-- Convert schema '/Users/johnn/Desktop/App-DBIx-Class-Migration/tutorial/share/migrations/_source/deploy/1/001-auto.yml' to '/Users/johnn/Desktop/App-DBIx-Class-Migration/tutorial/share/migrations/_source/deploy/2/001-auto.yml':;

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
COMMIT;

