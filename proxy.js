const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3110;

// Telemetry API — URL and Basic Auth from env (no credentials in code)
const TARGET = process.env.RTV_API_TARGET || 'https://telemetry.mock.sixfold.com';
const API_USER = process.env.RTV_API_USERNAME;
const API_PASS = process.env.RTV_API_PASSWORD;

if (!API_USER || !API_PASS) {
    console.error('Missing RTV_API_USERNAME or RTV_API_PASSWORD. Set them when starting the container.');
    process.exit(1);
}

const AUTH = 'Basic ' + Buffer.from(`${API_USER}:${API_PASS}`).toString('base64');

app.use(express.json());

// CORS headers for local development
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') return res.sendStatus(204);
    next();
});

// Serve index.html and static files from the same directory
app.use(express.static(path.join(__dirname)));

// Proxy all /api/* requests to the Sixfold mock API
app.all('/api/*', async (req, res) => {
    const apiPath = req.originalUrl.replace(/^\/api/, '');
    const url = TARGET + apiPath;

    const headers = {
        'Authorization': AUTH,
        'Content-Type': 'application/json'
    };

    const fetchOpts = {
        method: req.method,
        headers
    };

    if (req.method !== 'GET' && req.method !== 'HEAD' && req.body && Object.keys(req.body).length > 0) {
        fetchOpts.body = JSON.stringify(req.body);
    }

    try {
        const upstream = await fetch(url, fetchOpts);
        const text = await upstream.text();
        res.status(upstream.status);
        upstream.headers.forEach((value, key) => {
            if (!['content-encoding', 'transfer-encoding', 'connection'].includes(key.toLowerCase())) {
                res.setHeader(key, value);
            }
        });
        res.send(text);
    } catch (err) {
        console.error('Proxy error:', err.message);
        res.status(502).json({ error: 'Proxy could not reach upstream API', detail: err.message });
    }
});

app.listen(PORT, () => {
    console.log(`RTV Tour Builder proxy running at http://localhost:${PORT}`);
    console.log(`  App:  http://localhost:${PORT}/index.html`);
    console.log(`  API:  proxied to ${TARGET}`);
});
