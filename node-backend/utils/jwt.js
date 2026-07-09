const jwt = require('jsonwebtoken');
const { config } = require('../config');

const JWT_EXPIRY = '30d';

function signToken(user) {
  return jwt.sign(
    { id: user.id, role: user.role, name: user.name },
    config.jwtSecret,
    { expiresIn: JWT_EXPIRY },
  );
}

module.exports = { signToken, JWT_EXPIRY };
