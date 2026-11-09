-- Run 000_check_booking_payment_duplicates.sql first and resolve any duplicates.
-- Back up the database, then apply this migration once.
ALTER TABLE bookings
  ADD COLUMN active_slot TINYINT GENERATED ALWAYS AS (
    IF(status IN ('pending', 'approved'), 1, NULL)
  ) STORED,
  ADD UNIQUE KEY uq_no_double_booking (stall_id, booking_date, active_slot);

ALTER TABLE payments
  ADD UNIQUE KEY uq_one_payment_per_booking (booking_id);
