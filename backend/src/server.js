const { createApp } = require('./app');
const { createStore } = require('./store');

const PORT = Number(process.env.PORT) || 3000;
// 0.0.0.0, not localhost, so an emulator or a phone on the same network can
// reach it.
const HOST = '0.0.0.0';

createApp({ store: createStore() }).listen(PORT, HOST, () => {
  console.log(`jWallet Lite API on http://${HOST}:${PORT}/api/v1`);
});
