-- Convert schema '/Users/johnn/Desktop/DBIx-Class-Migration/examples/tutorial/share/migrations/_source/deploy/1/001-auto.yml' to '/Users/johnn/Desktop/DBIx-Class-Migration/examples/tutorial/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `country` (
  country_id integer NOT NULL,
  name varchar(96) NOT NULL,
  PRIMARY KEY (country_id)
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE artist ADD COLUMN country_fk integer NOT NULL,
                   ADD INDEX artist_idx_country_fk (country_fk),
                   ADD CONSTRAINT artist_fk_country_fk FOREIGN KEY (country_fk) REFERENCES country (country_id) ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE track DROP FOREIGN KEY track_fk_cd_fk;

;
ALTER TABLE track ADD CONSTRAINT track_fk_cd_fk FOREIGN KEY (cd_fk) REFERENCES cd (cd_id);

;

COMMIT;

