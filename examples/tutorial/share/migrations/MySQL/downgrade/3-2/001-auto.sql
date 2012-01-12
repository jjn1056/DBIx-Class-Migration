-- Convert schema '/Users/johnn/Desktop/DBIx-Class-Migration/examples/tutorial/share/migrations/_source/deploy/3/001-auto.yml' to '/Users/johnn/Desktop/DBIx-Class-Migration/examples/tutorial/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE cd ADD COLUMN artist_fk integer NOT NULL,
               ADD INDEX cd_idx_artist_fk (artist_fk),
               ADD CONSTRAINT cd_fk_artist_fk FOREIGN KEY (artist_fk) REFERENCES artist (artist_id) ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE track DROP FOREIGN KEY track_fk_cd_fk;

;
ALTER TABLE track ADD CONSTRAINT track_fk_cd_fk FOREIGN KEY (cd_fk) REFERENCES cd (cd_id);

;
ALTER TABLE artist_cd DROP FOREIGN KEY artist_cd_fk_artist_fk,
                      DROP FOREIGN KEY artist_cd_fk_cd_fk;

;
DROP TABLE artist_cd;

;

COMMIT;

