-- Convert schema '/Users/johnn/Desktop/DBIx-Class-Migration/examples/tutorial/share/migrations/_source/deploy/2/001-auto.yml' to '/Users/johnn/Desktop/DBIx-Class-Migration/examples/tutorial/share/migrations/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `artist_cd` (
  `artist_fk` integer NOT NULL,
  `cd_fk` integer NOT NULL,
  INDEX `artist_cd_idx_artist_fk` (`artist_fk`),
  INDEX `artist_cd_idx_cd_fk` (`cd_fk`),
  PRIMARY KEY (`artist_fk`, `cd_fk`),
  CONSTRAINT `artist_cd_fk_artist_fk` FOREIGN KEY (`artist_fk`) REFERENCES `artist` (`artist_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `artist_cd_fk_cd_fk` FOREIGN KEY (`cd_fk`) REFERENCES `cd` (`cd_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

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

