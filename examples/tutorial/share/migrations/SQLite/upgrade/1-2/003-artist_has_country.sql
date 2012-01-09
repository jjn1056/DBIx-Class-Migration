-- Convert schema '/Users/johnn/Desktop/App-DBIx-Class-Migration/tutorial/share/migrations/_source/deploy/1/001-auto.yml' to '/Users/johnn/Desktop/App-DBIx-Class-Migration/tutorial/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

CREATE TEMPORARY TABLE artist_temp_alter (
  artistid INTEGER PRIMARY KEY NOT NULL,
  name varchar(96) NOT NULL
);

INSERT INTO artist_temp_alter SELECT artistid, name FROM artist;

DROP TABLE artist;

CREATE TABLE artist (
  artistid INTEGER PRIMARY KEY NOT NULL,
  countryfk integer NOT NULL DEFAULT 1,
  name varchar(96) NOT NULL,
  FOREIGN KEY(countryfk) REFERENCES country(countryid)
);

CREATE INDEX artist_idx_countryfk ON artist (countryfk);

INSERT INTO artist SELECT artistid, 1, name FROM artist_temp_alter;

DROP TABLE artist_temp_alter;

COMMIT;

