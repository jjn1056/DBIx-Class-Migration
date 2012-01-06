-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Fri Jan  6 09:56:35 2012
-- 

;
BEGIN TRANSACTION;
--
-- Table: cd
--
CREATE TABLE cd (
  cdid INTEGER PRIMARY KEY NOT NULL,
  title varchar(96) NOT NULL
);
--
-- Table: country
--
CREATE TABLE country (
  countryid INTEGER PRIMARY KEY NOT NULL,
  code char(3) NOT NULL
);
CREATE UNIQUE INDEX country_code ON country (code);
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
-- Table: track
--
CREATE TABLE track (
  trackid INTEGER PRIMARY KEY NOT NULL,
  cd integer NOT NULL,
  title varchar(96) NOT NULL,
  FOREIGN KEY(cd) REFERENCES cd(cdid)
);
CREATE INDEX track_idx_cd ON track (cd);
--
-- Table: artist_cd
--
CREATE TABLE artist_cd (
  artistfk integer NOT NULL,
  cdfk integer NOT NULL,
  PRIMARY KEY (artistfk, cdfk),
  FOREIGN KEY(artistfk) REFERENCES artist(artistid),
  FOREIGN KEY(cdfk) REFERENCES cd(cdid)
);
CREATE INDEX artist_cd_idx_artistfk ON artist_cd (artistfk);
CREATE INDEX artist_cd_idx_cdfk ON artist_cd (cdfk);
COMMIT