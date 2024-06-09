const express = require('express');
const httpProxy = require('http-proxy');
const { execSync } = require('child_process');
const fs = require('fs');
const net = require('net');
const dgram = require('dgram');
const http = require('http');
const url = require('url');


const MAX_CONNECTIONS_PER_IP = 100;
const CONNECTION_TIMEOUT = 60000;
const BLACKLIST_TIMEOUT = 300000;
const MAX_REQUESTS_PER_MINUTE = 100;
const LOG_FILE = 'logs.txt';

const connections = {};
const blacklist = {};
const requestCounts = {};

function addToBlacklist(ip) {
    console.log(`Blacklisting IP address: ${ip}`);
    blacklist[ip] = true;
    setTimeout(() => {
        console.log(`Removing IP address from blacklist: ${ip}`);
        delete blacklist[ip];
    }, BLACKLIST_TIMEOUT);
}

function logDDoSAttack(ip, pps) {
    const logLine = `DDoS Attack Detected: IP ${ip} | Packets per second: ${pps}\n`;
    fs.appendFile(LOG_FILE, logLine, (err) => {
        if (err) {
            console.error('Error writing to logs file:', err);
        }
    });
}

function handleIncomingData(socket, remoteAddress) {
    let packetCount = 0;
    let pps = 0;
    const interval = setInterval(() => {
        pps = packetCount;
        packetCount = 0;
    }, 1000);

    socket.on('data', data => {
        packetCount++;
        console.log(`Received data from ${remoteAddress}: ${data}`);
    });

    socket.on('end', () => {
        clearInterval(interval);
        connections[remoteAddress]--;
        console.log(`Connection closed with ${remoteAddress}`);
    });

    socket.on('error', err => {
        clearInterval(interval);
        console.error(`Error with connection from ${remoteAddress}: ${err.message}`);
        connections[remoteAddress]--;
        socket.destroy();
    });

    setInterval(() => {
        if (pps > MAX_CONNECTIONS_PER_IP) {
            console.log(`DDoS attack detected from ${remoteAddress}. Packets per second: ${pps}`);
            logDDoSAttack(remoteAddress, pps);
            addToBlacklist(remoteAddress);
            clearInterval(interval); 
            socket.destroy(); 
        }
    }, 1000);
}

function applyFirewallRules(socket, remoteAddress) {
    if (blacklist[remoteAddress]) {
        console.log(`Rejected connection from blacklisted IP: ${remoteAddress}`);
        socket.destroy();
        return;
    }
    connections[remoteAddress] = (connections[remoteAddress] || 0) + 1;
    socket.setTimeout(CONNECTION_TIMEOUT, () => {
        connections[remoteAddress]--;
        console.log(`Connection timeout for ${remoteAddress}`);
    });
    handleIncomingData(socket, remoteAddress);
}

const tcpServer = net.createServer(socket => {
    const { remoteAddress } = socket;
    console.log(`Incoming TCP connection from ${remoteAddress}`);
    applyFirewallRules(socket, remoteAddress);
});


const udpServer = dgram.createSocket('udp4');
udpServer.on('error', (err) => {
    console.error(`UDP server error:\n${err.stack}`);
    udpServer.close();
});
udpServer.on('message', (msg, rinfo) => {
    const remoteAddress = rinfo.address;
    console.log(`Incoming UDP message from ${remoteAddress}`);
    applyFirewallRules(udpServer, remoteAddress);
});
udpServer.on('listening', () => {
    const address = udpServer.address();
    console.log(`UDP server listening ${address.address}:${address.port}`);
});
udpServer.bind();

const PORT = 0; 
tcpServer.listen(PORT, () => {
    console.log(`TCP server is listening on all available ports`);
});


const app = express();
const proxy = httpProxy.createProxyServer({});


app.use((req, res, next) => {
    const remoteAddress = req.connection.remoteAddress;
    if (blacklist[remoteAddress]) {
        res.status(403).send('Forbidden');
        return;
    }

    const currentTime = Math.floor(Date.now() / 60000); 
    requestCounts[remoteAddress] = requestCounts[remoteAddress] || {};
    requestCounts[remoteAddress][currentTime] = (requestCounts[remoteAddress][currentTime] || 0) + 1;

    const requestCount = Object.values(requestCounts[remoteAddress]).reduce((a, b) => a + b, 0);

    if (requestCount > MAX_REQUESTS_PER_MINUTE) {
        console.log(`DDoS attack detected from ${remoteAddress}. Requests per minute: ${requestCount}`);
        logDDoSAttack(remoteAddress, requestCount);
        addToBlacklist(remoteAddress);
        res.status(403).send('Forbidden');
    } else {
        next();
    }
});




app.use((req, res) => {
    const target = 'http://localhost';
    proxy.web(req, res, { target: `${target}${req.url}` });
});

app.listen(5587, () => {
    console.log('HTTP server with Layer 7 protection is listening on port 5587');
});
