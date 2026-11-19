'use strict';
const express = require('express');
const helmet = require('helmet');

const AUTH_URL = process.env.AUTH_URL || 'http://auth-service:8000';
// Lab only: lets you break probes on purpose (docs/labs.md). Keep false in real envs.
const FAULT = process.env.ENABLE_FAULT_INJECTION === 'true';

function createApp() {
  const app = express();
  app.disable('x-powered-by');
  app.use(helmet());
  app.use(express.json({ limit: '10kb' }));

  const state = { live: true, ready: true };
  const orders = [];
  const products = [
    { id: 1, name: 'Laptop', price: 800 },
    { id: 2, name: 'Phone', price: 500 },
    { id: 3, name: 'Headphones', price: 120 },
  ];

  // Three separate probe endpoints (see docs/runbooks/probes.md for reasoning)
  app.get('/health/startup', (_q, r) => r.json({ status: 'started' }));
  app.get('/health/live', (_q, r) => (state.live ? r.json({ status: 'alive' }) : r.status(500).json({ status: 'unhealthy' })));
  app.get('/health/ready', (_q, r) => (state.ready ? r.json({ status: 'ready' }) : r.status(503).json({ status: 'not-ready' })));
  if (FAULT) {
    app.post('/debug/unhealthy', (_q, r) => { state.live = false; r.json({ live: false }); });
    app.post('/debug/unready', (_q, r) => { state.ready = false; r.json({ ready: false }); });
  }

  app.get('/api/products', (_q, r) => r.json(products));

  app.post('/api/login', async (req, res) => {
    try {
      const r = await fetch(`${AUTH_URL}/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(req.body || {}),
        signal: AbortSignal.timeout(3000),
      });
      res.status(r.status).json(await r.json());
    } catch (e) {
      res.status(502).json({ error: 'auth-service unreachable' });
    }
  });

  async function requireAuth(req, res, next) {
    const h = req.get('authorization');
    if (!h) return res.status(401).json({ error: 'missing token' });
    try {
      const r = await fetch(`${AUTH_URL}/verify`, { headers: { authorization: h }, signal: AbortSignal.timeout(3000) });
      if (!r.ok) return res.status(401).json({ error: 'invalid token' });
      req.user = (await r.json()).sub;
      return next();
    } catch (e) {
      return res.status(502).json({ error: 'auth-service unreachable' });
    }
  }

  app.get('/api/orders', requireAuth, (req, res) => res.json(orders.filter((o) => o.user === req.user)));
  app.post('/api/orders', requireAuth, (req, res) => {
    const { productId, qty } = req.body || {};
    if (!Number.isInteger(productId) || !Number.isInteger(qty) || qty < 1 || qty > 100) {
      return res.status(400).json({ error: 'invalid input' });
    }
    const o = { id: orders.length + 1, user: req.user, productId, qty };
    orders.push(o);
    return res.status(201).json(o);
  });
  return app;
}

module.exports = { createApp };

if (require.main === module) {
  const port = Number(process.env.PORT || 3000);
  const server = createApp().listen(port, '0.0.0.0', () => console.log(`backend-api on ${port}`));
  process.on('SIGTERM', () => server.close(() => process.exit(0))); // graceful shutdown
}
