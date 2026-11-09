-- Resolve every returned row before applying 001_booking_payment_constraints.sql.
SELECT stall_id, booking_date, COUNT(*) AS active_count
FROM bookings
WHERE status IN ('pending', 'approved')
GROUP BY stall_id, booking_date
HAVING COUNT(*) > 1;

SELECT booking_id, COUNT(*) AS payment_count
FROM payments
GROUP BY booking_id
HAVING COUNT(*) > 1;
