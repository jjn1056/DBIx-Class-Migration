
BEGIN;

;
ALTER TABLE cd DROP FOREIGN KEY cd_fk_artist_fk,
               DROP INDEX cd_idx_artist_fk,
               DROP COLUMN artist_fk;

;
ALTER TABLE track DROP FOREIGN KEY track_fk_cd_fk;

;
ALTER TABLE track ADD CONSTRAINT track_fk_cd_fk FOREIGN KEY (cd_fk) REFERENCES cd (cd_id) ON DELETE CASCADE ON UPDATE CASCADE;

;


COMMIT;

