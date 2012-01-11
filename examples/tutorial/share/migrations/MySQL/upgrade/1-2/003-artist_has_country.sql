-- Convert schema '/Users/johnn/Desktop/App-DBIx-Class-Migration/tutorial/share/migrations/_source/deploy/1/001-auto.yml' to '/Users/johnn/Desktop/App-DBIx-Class-Migration/tutorial/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

SET foreign_key_checks=0;

;
ALTER TABLE artist ADD COLUMN country_fk integer NOT NULL,
                   ADD INDEX artist_idx_country_fk (country_fk),
                   ADD CONSTRAINT artist_fk_country_fk FOREIGN KEY (country_fk) REFERENCES country (country_id) ON DELETE CASCADE ON UPDATE CASCADE;

UPDATE INTO artist(country_fk) values(1);

;
ALTER TABLE track DROP FOREIGN KEY track_fk_cd_fk;

;
ALTER TABLE track ADD CONSTRAINT track_fk_cd_fk FOREIGN KEY (cd_fk) REFERENCES cd (cd_id);

;

SET foreign_key_checks=1;

COMMIT;


____



