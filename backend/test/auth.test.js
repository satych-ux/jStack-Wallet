const { test } = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');

const { createApp } = require('../src/app');
const { createStore } = require('../src/store');

const app = () => createApp({ store: createStore() });
const TOKEN = 'mock_access_token_123';
const DEMO_USER = { id: 'USR1001', name: 'Aditi Verma', email: 'demo@jstack.co' };

/** Asserts the full error shape: status, code, a message, and fields only when expected. */
function assertError(res, status, code, fields) {
  assert.equal(res.status, status);
  assert.equal(res.body.success, false);
  assert.equal(res.body.error.code, code);
  assert.equal(typeof res.body.error.message, 'string');
  assert.ok(res.body.error.message.length > 0);
  if (fields === undefined) {
    assert.equal(res.body.error.fields, undefined);
  } else {
    assert.deepEqual(Object.keys(res.body.error.fields).sort(), fields);
  }
}

const login = (body) => request(app()).post('/api/v1/auth/login').send(body);

// --- POST /auth/login (API-01, API-02) ---

test('correct credentials return 200 with accessToken and user {id, name, email}', async () => {
  const res = await login({ email: 'demo@jstack.co', password: 'Demo@123' });

  assert.equal(res.status, 200);
  assert.deepEqual(res.body, {
    success: true,
    data: { accessToken: TOKEN, user: DEMO_USER },
  });
});

test('the password never appears in the response', async () => {
  const res = await login({ email: 'demo@jstack.co', password: 'Demo@123' });

  assert.doesNotMatch(JSON.stringify(res.body), /Demo@123|password/);
});

test('email is matched trimmed and case-insensitively', async () => {
  const res = await login({ email: '  Demo@JStack.co ', password: 'Demo@123' });

  assert.equal(res.status, 200);
});

test('wrong password returns 401 INVALID_CREDENTIALS', async () => {
  const res = await login({ email: 'demo@jstack.co', password: 'wrong' });

  assertError(res, 401, 'INVALID_CREDENTIALS');
  assert.equal(res.body.error.message, 'Invalid email or password');
});

test('password is matched exactly (case and spaces count)', async () => {
  for (const password of ['demo@123', ' Demo@123', 'Demo@123 ']) {
    const res = await login({ email: 'demo@jstack.co', password });
    assert.equal(res.status, 401, password);
  }
});

test('unknown email returns 401 with the same code and message as a wrong password', async () => {
  const wrongPassword = await login({ email: 'demo@jstack.co', password: 'wrong' });
  const unknownEmail = await login({ email: 'nobody@jstack.co', password: 'Demo@123' });

  assert.equal(unknownEmail.status, 401);
  assert.deepEqual(unknownEmail.body, wrongPassword.body);
});

test('missing email or password returns 400 naming the missing field', async () => {
  assertError(await login({ password: 'Demo@123' }), 400, 'VALIDATION_ERROR', ['email']);
  assertError(await login({ email: 'demo@jstack.co' }), 400, 'VALIDATION_ERROR', ['password']);
});

test('an empty body returns 400 naming both fields', async () => {
  const res = await request(app()).post('/api/v1/auth/login');

  assertError(res, 400, 'VALIDATION_ERROR', ['email', 'password']);
});

test('blank or non-string email/password returns 400 naming that field', async () => {
  for (const [body, field] of [
    [{ email: '   ', password: 'Demo@123' }, 'email'],
    [{ email: 123, password: 'Demo@123' }, 'email'],
    [{ email: 'demo@jstack.co', password: '' }, 'password'],
    [{ email: 'demo@jstack.co', password: '   ' }, 'password'],
    [{ email: 'demo@jstack.co', password: ['Demo@123'] }, 'password'],
  ]) {
    assertError(await login(body), 400, 'VALIDATION_ERROR', [field]);
  }
});

test('a JSON array body returns 400 naming both fields', async () => {
  const res = await request(app()).post('/api/v1/auth/login').send([]);

  assertError(res, 400, 'VALIDATION_ERROR', ['email', 'password']);
});

// --- GET /users/profile (API-03) ---

const profile = (authorization) => {
  const req = request(app()).get('/api/v1/users/profile');
  return authorization === undefined ? req : req.set('Authorization', authorization);
};

test('/users/profile with no Authorization header returns 401', async () => {
  const res = await profile();

  assertError(res, 401, 'UNAUTHORIZED');
  assert.equal(res.body.error.message, 'Missing or invalid access token');
});

test('/users/profile with a wrong token returns 401', async () => {
  for (const header of ['Bearer wrong', TOKEN, `Basic ${TOKEN}`, 'Bearer ', `Bearer ${TOKEN}x`]) {
    assertError(await profile(header), 401, 'UNAUTHORIZED');
  }
});

test('/users/profile with the valid token returns 200 and the user', async () => {
  const res = await profile(`Bearer ${TOKEN}`);

  assert.equal(res.status, 200);
  assert.deepEqual(res.body, { success: true, data: DEMO_USER });
});

test('the token from login opens /users/profile', async () => {
  const server = app();
  const { body } = await request(server)
    .post('/api/v1/auth/login')
    .send({ email: 'demo@jstack.co', password: 'Demo@123' });

  const res = await request(server)
    .get('/api/v1/users/profile')
    .set('Authorization', `Bearer ${body.data.accessToken}`);

  assert.equal(res.status, 200);
});
