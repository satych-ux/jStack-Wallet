/** Longest delay allowed, so a typo can't hang a request for minutes. */
const MAX_LATENCY_MS = 30000;

/** `?simulateLatencyMs=` as whole milliseconds (digits only); anything else is 0. */
function latencyMs(value) {
  if (typeof value !== 'string' || !/^\d+$/.test(value)) return 0;
  return Math.min(Number(value), MAX_LATENCY_MS);
}

/**
 * Demo only (API-15): `?simulateLatencyMs=500` holds every JSON response
 * back by 500 ms, errors and replays included, like a slow server.
 *
 * The route itself still runs at once; only the answer waits. So a slow
 * transfer has already deducted and stored its Idempotency-Key when the app
 * times out, and a retry with the same key gets the stored answer. That is
 * the case idempotency exists for. The routes stay synchronous: no `await`
 * is added anywhere (DECISIONS row 104).
 *
 * Guards, so a delayed answer behaves like an immediate one:
 * - only the first answer is sent (without a delay, Express itself would
 *   refuse a second one; here it would fire later, inside a timer);
 * - the status is the one set when the route answered; while the answer
 *   waits, Express doesn't know it was given, and the error handler could
 *   otherwise turn a 200 into a 500;
 * - a failure while sending is logged instead of thrown, because an error
 *   thrown inside a timer would stop the whole process.
 */
function simulateLatency(req, res, next) {
  const ms = latencyMs(req.query.simulateLatencyMs);
  if (ms > 0) {
    const send = res.json.bind(res);
    let answered = false;
    res.json = (body) => {
      if (answered) return res;
      answered = true;
      const status = res.statusCode;
      setTimeout(() => {
        try {
          res.status(status);
          send(body);
        } catch (err) {
          console.error(err);
        }
      }, ms);
      return res;
    };
  }
  next();
}

module.exports = { simulateLatency, latencyMs, MAX_LATENCY_MS };
