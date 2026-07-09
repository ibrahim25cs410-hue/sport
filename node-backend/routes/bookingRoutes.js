const express = require('express');
const bookingController = require('../controllers/bookingController');
const legacyBookingController = require('../controllers/legacyBookingController');
const { auth } = require('../middleware/auth');
const { checkRole } = require('../middleware/checkRole');

const router = express.Router();

// Task 3 — stadium bookings (register /me routes before :param routes)
router.get('/bookings/user/me', auth, checkRole(['user']), bookingController.getUserBookings);
router.get('/bookings/owner/me', auth, checkRole(['owner']), bookingController.getOwnerBookings);

router.post('/bookings', auth, (req, res, next) => {
  if (req.body?.fieldId != null) {
    return legacyBookingController.createFieldBooking(req, res);
  }
  return checkRole(['user'])(req, res, () => bookingController.createBooking(req, res));
});

router.patch('/bookings/:id/status', auth, checkRole(['owner']), bookingController.updateBookingStatus);

// Legacy field bookings (Flutter app)
router.get('/bookings/user/:userId', auth, legacyBookingController.getUserFieldBookings);
router.get('/bookings/user/:userId/history', auth, legacyBookingController.getUserFieldBookingHistory);
router.post('/bookings/cancel', auth, legacyBookingController.cancelFieldBooking);
router.get('/bookings/owner/:ownerId', auth, legacyBookingController.getOwnerFieldBookings);
router.post('/bookings/approve', auth, legacyBookingController.approveFieldBooking);
router.post('/bookings/reject', auth, legacyBookingController.rejectFieldBooking);

router.post('/bookings/:bookingId/pay/initiate', auth, (req, res) => {
  res.json({
    transactionToken: `demo-${req.params.bookingId}`,
    gateway: req.body?.gateway || 'card',
    amount: 0,
    checkoutUrl: null,
  });
});
router.post('/bookings/pay/verify', auth, (_req, res) => {
  res.json({
    success: true,
    status: 'paid',
    invoiceId: null,
    outstandingAmount: 0,
    message: 'تم',
  });
});

module.exports = router;
