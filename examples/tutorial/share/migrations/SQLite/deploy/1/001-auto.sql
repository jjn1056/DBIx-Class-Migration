-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Thu Jan  5 11:56:50 2012
-- 

;
BEGIN TRANSACTION;
--
-- Table: artist
--
CREATE TABLE artist (
  artistid INTEGER PRIMARY KEY NOT NULL,
  name varchar(96) NOT NULL
);
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