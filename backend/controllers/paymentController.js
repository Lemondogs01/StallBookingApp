const Payment = require('../models/Payment');
const removeUploadedFile = require('../utils/removeUploadedFile');
const removeUploadedFileUrl = require('../utils/removeUploadedFileUrl');

const createPayment = async (req, res) => {
  let paymentSaved = false;
  try {
    const body = req.body ?? {};
    const bookingId = Number(body.booking_id);
    const submittedAmount = Number(body.amount);

    if (!Number.isInteger(bookingId) || bookingId < 1 || !Number.isFinite(submittedAmount) || submittedAmount <= 0) {
      await removeUploadedFile(req.file);
      return res.status(400).json({ message: 'A valid booking ID and payment amount are required.' });
    }
    if (!req.file) {
      return res.status(400).json({ message: 'A payment slip image is required.' });
    }

    const slip_url = `/uploads/slips/${req.file.filename}`;
    const payment = await Payment.createForPendingBooking({
      booking_id: bookingId,
      user_id: req.user.id,
      amount: submittedAmount,
      slip_url
    });
    paymentSaved = true;

    res.status(201).json({
      message: 'Payment slip uploaded successfully.',
      payment: {
        id: payment.id,
        booking_id: bookingId,
        amount: payment.amount,
        slip_url
      }
    });
  } catch (error) {
    if (!paymentSaved) await removeUploadedFile(req.file);
    if (error.status) {
      return res.status(error.status).json({ message: error.message });
    }
    if (error.code === 'ER_DUP_ENTRY' && error.errno === 1062) {
      return res.status(409).json({ message: 'A payment slip has already been submitted for this booking.' });
    }
    console.error('Create payment error:', error);
    res.status(500).json({ message: 'Internal server error creating payment.' });
  }
};

const replacePaymentSlip = async (req, res) => {
  let slipSaved = false;
  try {
    const bookingId = Number(req.params.bookingId);
    if (!Number.isInteger(bookingId) || bookingId < 1) {
      await removeUploadedFile(req.file);
      return res.status(400).json({ message: 'A valid booking ID is required.' });
    }
    if (!req.file) {
      return res.status(400).json({ message: 'A replacement payment slip image is required.' });
    }

    const slip_url = `/uploads/slips/${req.file.filename}`;
    const result = await Payment.replaceSlipForPendingBooking({
      booking_id: bookingId,
      user_id: req.user.id,
      slip_url
    });
    slipSaved = true;

    await removeUploadedFileUrl(result.old_slip_url, 'slips');

    res.json({
      message: 'Payment slip replaced successfully.',
      payment: { booking_id: bookingId, slip_url }
    });
  } catch (error) {
    if (!slipSaved) await removeUploadedFile(req.file);
    if (error.status) {
      return res.status(error.status).json({ message: error.message });
    }
    console.error('Replace payment slip error:', error);
    res.status(500).json({ message: 'Internal server error replacing payment slip.' });
  }
};

module.exports = { createPayment, replacePaymentSlip };
