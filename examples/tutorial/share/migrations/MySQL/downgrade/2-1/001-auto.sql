-- Convert schema '/Users/johnn/Desktop/DBIx-Class-Migration/examples/tutorial/share/migrations/_source/deploy/2/001-auto.yml' to '/Users/johnn/Desktop/DBIx-Class-Migration/examples/tutorial/share/migrations/_source/deploy/1/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE artist DROP FOREIGN KEY artist_fk_country_fk,
                   DROP INDEX artist_idx_country_fk,
                   DROP COLUMN country_fk;

;
ALTER TABLE track DROP FOREIGN KEY track_fk_cd_fk;

;
ALTER TABLE track ADD CONSTRAINT track_fk_cd_fk FOREIGN KEY (cd_fk) REFERENCES cd (cd_id) ON DELETE CASCADE ON UPDATE CASCADE;

;
DROP TABLE country;

;

COMMIT;

