const express = require('express');
const authController = require('../controllers/authController');
const { auth } = require('../middleware/auth');
const { authLimiter } = require('../middleware/rateLimiter');

const router = express.Router();

// REST-style auth endpoints
router.post('/auth/register', authLimiter, authController.register);
router.post('/auth/login', authLimiter, authController.login);
router.get('/auth/me', auth, authController.getMe);
router.put('/auth/me', auth, authController.updateMe);

// Legacy endpoints (Flutter mobile app contract)
router.post('/register-user', authLimiter, authController.registerUser);
router.post('/register-owner', authLimiter, authController.registerOwner);
router.post('/login', authLimiter, authController.login);
router.get('/me', auth, authController.getMe);
router.put('/me', auth, authController.updateMe);

module.exports = router;
