'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { createApp } = require('../src/server');

test('health, products and auth guard', async () => {
  const server = createApp().listen(0);
  const base = `http://127.0.0.1:${server.address().port}`;
  try {
    assert.strictEqual((await fetch(`${base}/health/live`)).status, 200);
    assert.strictEqual((await fetch(`${base}/health/ready`)).status, 200);
    const p = await (await fetch(`${base}/api/products`)).json();
    assert.ok(p.length > 0);
    assert.strictEqual((await fetch(`${base}/api/orders`)).status, 401);
  } finally {
    server.close();
  }
});
