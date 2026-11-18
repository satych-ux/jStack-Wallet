const express = require('express');

const healthRoutes = require('./routes/health');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const walletRoutes = require('./routes/wallet');
const transactionRoutes = require('./routes/transactions');
const { cors } = require('./middleware/cors');
const { simulateLatency } = require('./middleware/latency');
const { notFound, errorHandler } = require('./middleware/errorHandler');

/**
 * Builds the Express app without starting it, so tests can drive it with
 * supertest. The store is passed in: each test gets its own fresh state.
 */
function createApp({ store }) {
  const app = express();
  app.locals.store = store;

  // Every response is live data. Without this, Express adds an ETag and can
  // answer a repeat request with an empty 304.
  app.set('etag', false);

  app.use(cors);
  app.use(simulateLatency);
  app.use(express.json());

  app.use('/api/v1/health', healthRoutes);
  app.use('/api/v1/auth', authRoutes);
  app.use('/api/v1/users', userRoutes);
  app.use('/api/v1/wallet', walletRoutes);
  app.use('/api/v1/transactions', transactionRoutes);

  app.use(notFound);
  app.use(errorHandler);
  return app;
}

module.exports = { createApp };
