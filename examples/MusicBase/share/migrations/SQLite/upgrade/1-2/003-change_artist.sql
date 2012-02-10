BEGIN;

CREATE TEMPORARY TABLE artist_temp_alter (
  artist_id INTEGER PRIMARY KEY NOT NULL,
  name varchar(96) NOT NULL
);

INSERT INTO artist_temp_alter SELECT artist_id, name FROM artist;

DROP TABLE artist;

CREATE TABLE artist (
  artist_id INTEGER PRIMARY KEY NOT NULL,
  country_fk integer NOT NULL DEFAULT 1,
  name varchar(96) NOT NULL,
  FOREIGN KEY(country_fk) REFERENCES country(country_id)
);

CREATE INDEX artist_idx_country_fk ON artist (country_fk);

INSERT INTO artist SELECT artist_id, 1, name FROM artist_temp_alter;

DROP TABLE artist_temp_alter;

COMMIT;


