-- Convert schema '/Users/johnn/Desktop/MusicBase/share/migrations/_source/deploy/3/001-auto.yml' to '/Users/johnn/Desktop/MusicBase/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE cd ADD COLUMN artist_fk integer NOT NULL;

;
CREATE INDEX cd_idx_artist_fk ON cd (artist_fk);

;
CREATE TEMPORARY TABLE country_temp_alter (
  country_id INTEGER PRIMARY KEY NOT NULL,
  name varchar(96) NOT NULL
);

;
INSERT INTO country_temp_alter SELECT country_id, name FROM country;

;
DROP TABLE country;

;
CREATE TABLE country (
  country_id INTEGER PRIMARY KEY NOT NULL,
  name varchar(96) NOT NULL
);

;
CREATE UNIQUE INDEX country_name02 ON country (name);

;
INSERT INTO country SELECT country_id, name FROM country_temp_alter;

;
DROP TABLE country_temp_alter;

;
DROP TABLE artist_cd;

;

COMMIT;

