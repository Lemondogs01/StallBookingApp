ALTER TABLE bookings
    ADD COLUMN approved_by_user_id INT NULL AFTER status,
    ADD COLUMN approved_at DATETIME NULL AFTER approved_by_user_id,
    ADD KEY idx_bookings_approved_by_user_id (approved_by_user_id),
    ADD CONSTRAINT fk_bookings_approved_by_user
        FOREIGN KEY (approved_by_user_id) REFERENCES users(id)
        ON DELETE SET NULL;
