-- Convert schema '/Users/johnn/Desktop/MusicBase/share/migrations/_source/deploy/2/001-auto.yml' to '/Users/johnn/Desktop/MusicBase/share/migrations/_source/deploy/1/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE artist_temp_alter (
  artist_id INTEGER PRIMARY KEY NOT NULL,
  name varchar(96) NOT NULL
);

;
INSERT INTO artist_temp_alter SELECT artist_id, name FROM artist;

;
DROP TABLE artist;

;
CREATE TABLE artist (
  artist_id INTEGER PRIMARY KEY NOT NULL,
  name varchar(96) NOT NULL
);

;
INSERT INTO artist SELECT artist_id, name FROM artist_temp_alter;

;
DROP TABLE artist_temp_alter;

;
DROP TABLE country;

;

COMMIT;

