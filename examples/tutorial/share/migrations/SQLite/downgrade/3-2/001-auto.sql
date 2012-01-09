-- Convert schema '/Users/johnn/Desktop/App-DBIx-Class-Migration/tutorial/share/migrations/_source/deploy/3/001-auto.yml' to '/Users/johnn/Desktop/App-DBIx-Class-Migration/tutorial/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE cd ADD COLUMN artist integer NOT NULL;

;
CREATE INDEX cd_idx_artist ON cd (artist);

;
CREATE TEMPORARY TABLE country_temp_alter (
  countryid INTEGER PRIMARY KEY NOT NULL,
  name varchar(96) NOT NULL
);

;
INSERT INTO country_temp_alter SELECT countryid, name FROM country;

;
DROP TABLE country;

;
CREATE TABLE country (
  countryid INTEGER PRIMARY KEY NOT NULL,
  name varchar(96) NOT NULL
);

;
INSERT INTO country SELECT countryid, name FROM country_temp_alter;

;
DROP TABLE country_temp_alter;

;
DROP TABLE artist_cd;

;

COMMIT;

