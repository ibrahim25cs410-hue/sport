const express = require('express');
const stadiumController = require('../controllers/stadiumController');
const { auth, optionalAuth } = require('../middleware/auth');
const { checkRole } = require('../middleware/checkRole');

const router = express.Router();

router.get('/stadiums', optionalAuth, stadiumController.listStadiums);
router.get('/stadiums/mine', auth, checkRole(['owner']), stadiumController.listMyStadiums);

router.post('/stadiums', auth, checkRole(['owner']), stadiumController.createStadium);
router.get('/stadiums/:id', optionalAuth, stadiumController.getStadium);
router.put('/stadiums/:id', auth, checkRole(['owner']), stadiumController.updateStadium);
router.delete('/stadiums/:id', auth, checkRole(['owner']), stadiumController.deleteStadium);

module.exports = router;
