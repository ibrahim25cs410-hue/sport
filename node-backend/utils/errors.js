const { config } = require('../config');

function serverError(res, error) {
  if (!config.isProd) {
    return res.status(500).json({ message: 'Server error', error: String(error) });
  }
  console.error(error);
  return res.status(500).json({ message: 'Server error' });
}

module.exports = { serverError };
