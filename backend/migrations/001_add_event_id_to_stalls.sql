-- Link generated stalls to their event while preserving existing standalone stalls.
ALTER TABLE stalls
  ADD COLUMN event_id INT NULL AFTER code,
  ADD KEY idx_stalls_event_id (event_id),
  ADD CONSTRAINT fk_stalls_event
    FOREIGN KEY (event_id) REFERENCES events (id)
    ON DELETE CASCADE;
