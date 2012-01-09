-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Thu Jan  5 16:28:55 2012
-- 

;
BEGIN TRANSACTION;
--
-- Table: country
--
CREATE TABLE country (
  countryid INTEGER PRIMARY KEY NOT NULL,
  name varchar(96) NOT NULL
);
--
-- Table: artist
--
CREATE TABLE artist (
  artistid INTEGER PRIMARY KEY NOT NULL,
  countryfk integer NOT NULL DEFAULT 1,
  name varchar(96) NOT NULL,
  FOREIGN KEY(countryfk) REFERENCES country(countryid)
);
CREATE INDEX artist_idx_countryfk ON artist (countryfk);
--
-- Table: cd
--
CREATE TABLE cd (
  cdid INTEGER PRIMARY KEY NOT NULL,
  artist integer NOT NULL,
  title varchar(96) NOT NULL,
  FOREIGN KEY(artist) REFERENCES artist(artistid)
);
CREATE INDEX cd_idx_artist ON cd (artist);
--
-- Table: track
--
CREATE TABLE track (
  trackid INTEGER PRIMARY KEY NOT NULL,
  cd integer NOT NULL,
  title varchar(96) NOT NULL,
  FOREIGN KEY(cd) REFERENCES cd(cdid)
);
CREATE INDEX track_idx_cd ON track (cd);
COMMIT