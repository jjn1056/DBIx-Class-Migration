-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Wed Feb  8 10:02:16 2012
-- 
;
SET foreign_key_checks=0;
--
-- Table: `cd`
--
CREATE TABLE `cd` (
  `cd_id` integer NOT NULL,
  `title` varchar(96) NOT NULL,
  PRIMARY KEY (`cd_id`)
) ENGINE=InnoDB;
--
-- Table: `country`
--
CREATE TABLE `country` (
  `country_id` integer NOT NULL,
  `code` char(3) NOT NULL,
  PRIMARY KEY (`country_id`),
  UNIQUE `country_code` (`code`)
) ENGINE=InnoDB;
--
-- Table: `artist`
--
CREATE TABLE `artist` (
  `artist_id` integer NOT NULL,
  `country_fk` integer NOT NULL,
  `name` varchar(96) NOT NULL,
  INDEX `artist_idx_country_fk` (`country_fk`),
  PRIMARY KEY (`artist_id`),
  CONSTRAINT `artist_fk_country_fk` FOREIGN KEY (`country_fk`) REFERENCES `country` (`country_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `track`
--
CREATE TABLE `track` (
  `track_id` integer NOT NULL,
  `cd_fk` integer NOT NULL,
  `title` varchar(96) NOT NULL,
  INDEX `track_idx_cd_fk` (`cd_fk`),
  PRIMARY KEY (`track_id`),
  CONSTRAINT `track_fk_cd_fk` FOREIGN KEY (`cd_fk`) REFERENCES `cd` (`cd_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `artist_cd`
--
CREATE TABLE `artist_cd` (
  `artist_fk` integer NOT NULL,
  `cd_fk` integer NOT NULL,
  INDEX `artist_cd_idx_artist_fk` (`artist_fk`),
  INDEX `artist_cd_idx_cd_fk` (`cd_fk`),
  PRIMARY KEY (`artist_fk`, `cd_fk`),
  CONSTRAINT `artist_cd_fk_artist_fk` FOREIGN KEY (`artist_fk`) REFERENCES `artist` (`artist_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `artist_cd_fk_cd_fk` FOREIGN KEY (`cd_fk`) REFERENCES `cd` (`cd_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
SET foreign_key_checks=1