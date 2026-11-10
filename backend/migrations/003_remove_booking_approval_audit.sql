-- Apply only to databases that previously ran 002_booking_approval_audit.sql.
ALTER TABLE bookings
    DROP FOREIGN KEY fk_bookings_approved_by_user,
    DROP INDEX idx_bookings_approved_by_user_id,
    DROP COLUMN approved_by_user_id,
    DROP COLUMN approved_at;
