const { test } = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');

const { createApp } = require('../src/app');
const { createStore } = require('../src/store');

const app = () => createApp({ store: createStore() });

test('GET /api/v1/health returns 200 in the success shape', async () => {
  const res = await request(app()).get('/api/v1/health');

  assert.equal(res.status, 200);
  assert.deepEqual(res.body, { success: true, data: { status: 'ok' } });
});

test('an unknown route returns 404 in the standard error shape', async () => {
  const res = await request(app()).get('/api/v1/nope');

  assert.equal(res.status, 404);
  assert.equal(res.body.success, false);
  assert.equal(res.body.error.code, 'NOT_FOUND');
  assert.equal(typeof res.body.error.message, 'string');
});

test('a malformed JSON body returns 400 in the standard error shape', async () => {
  const res = await request(app())
    .post('/api/v1/health')
    .set('Content-Type', 'application/json')
    .send('{"amount":');

  assert.equal(res.status, 400);
  assert.equal(res.body.success, false);
  assert.equal(res.body.error.code, 'VALIDATION_ERROR');
});

// Body problems express.json() raises itself. Each must be a 400 in the
// standard shape, never a 500 (the contract keeps 500 for server bugs).
const unreadableBodies = {
  'a body over the 100kb limit': (req) =>
    req.set('Content-Type', 'application/json').send(`{"pad":"${'x'.repeat(200 * 1024)}"}`),
  'an unsupported charset': (req) =>
    req.set('Content-Type', 'application/json; charset=klingon').send('{}'),
  'an unsupported Content-Encoding': (req) =>
    req.set('Content-Type', 'application/json').set('Content-Encoding', 'br2').send('{}'),
  'a gzip Content-Encoding on a plain body': (req) =>
    req.set('Content-Type', 'application/json').set('Content-Encoding', 'gzip').send('{}'),
};

for (const [name, send] of Object.entries(unreadableBodies)) {
  test(`${name} returns 400 VALIDATION_ERROR, not 500`, async (t) => {
    const logged = t.mock.method(console, 'error', () => {});
    const res = await send(request(app()).post('/api/v1/auth/login'));

    assert.equal(res.status, 400);
    assert.equal(res.body.success, false);
    assert.equal(res.body.error.code, 'VALIDATION_ERROR');
    assert.equal(typeof res.body.error.message, 'string');
    assert.equal(logged.mock.callCount(), 0, 'a client error is not logged as a bug');
  });
}

// --- CORS (backend decision 17): for Bruno, Swagger UI and browsers ---

test('a browser preflight gets 204 with CORS headers, before the auth check', async () => {
  const res = await request(app())
    .options('/api/v1/transactions/transfer')
    .set('Origin', 'http://localhost:5173')
    .set('Access-Control-Request-Method', 'POST')
    .set('Access-Control-Request-Headers', 'authorization, content-type, idempotency-key');

  assert.equal(res.status, 204);
  assert.equal(res.headers['access-control-allow-origin'], '*');
  const allowed = res.headers['access-control-allow-headers'].toLowerCase();
  for (const header of ['authorization', 'content-type', 'idempotency-key']) {
    assert.ok(allowed.includes(header), header);
  }
  assert.match(res.headers['access-control-allow-methods'], /POST/);
});

test('ordinary responses, errors included, carry Access-Control-Allow-Origin', async () => {
  const ok = await request(app()).get('/api/v1/health');
  const unauthorized = await request(app()).get('/api/v1/wallet/balance');

  assert.equal(ok.headers['access-control-allow-origin'], '*');
  assert.equal(unauthorized.status, 401);
  assert.equal(unauthorized.headers['access-control-allow-origin'], '*');
});
