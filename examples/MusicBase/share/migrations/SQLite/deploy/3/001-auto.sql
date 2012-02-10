-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Wed Feb  8 09:42:03 2012
-- 

;
BEGIN TRANSACTION;
--
-- Table: cd
--
CREATE TABLE cd (
  cd_id INTEGER PRIMARY KEY NOT NULL,
  title varchar(96) NOT NULL
);
--
-- Table: country
--
CREATE TABLE country (
  country_id INTEGER PRIMARY KEY NOT NULL,
  code char(3) NOT NULL
);
CREATE UNIQUE INDEX country_code ON country (code);
--
-- Table: artist
--
CREATE TABLE artist (
  artist_id INTEGER PRIMARY KEY NOT NULL,
  country_fk integer NOT NULL,
  name varchar(96) NOT NULL,
  FOREIGN KEY(country_fk) REFERENCES country(country_id)
);
CREATE INDEX artist_idx_country_fk ON artist (country_fk);
--
-- Table: track
--
CREATE TABLE track (
  track_id INTEGER PRIMARY KEY NOT NULL,
  cd_fk integer NOT NULL,
  title varchar(96) NOT NULL,
  FOREIGN KEY(cd_fk) REFERENCES cd(cd_id)
);
CREATE INDEX track_idx_cd_fk ON track (cd_fk);
--
-- Table: artist_cd
--
CREATE TABLE artist_cd (
  artist_fk integer NOT NULL,
  cd_fk integer NOT NULL,
  PRIMARY KEY (artist_fk, cd_fk),
  FOREIGN KEY(artist_fk) REFERENCES artist(artist_id),
  FOREIGN KEY(cd_fk) REFERENCES cd(cd_id)
);
CREATE INDEX artist_cd_idx_artist_fk ON artist_cd (artist_fk);
CREATE INDEX artist_cd_idx_cd_fk ON artist_cd (cd_fk);
COMMIT