-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Wed Jan 11 10:40:10 2012
-- 
;
SET foreign_key_checks=0;
--
-- Table: `artist`
--
CREATE TABLE `artist` (
  `artist_id` integer NOT NULL,
  `name` varchar(96) NOT NULL,
  PRIMARY KEY (`artist_id`)
) ENGINE=InnoDB;
--
-- Table: `cd`
--
CREATE TABLE `cd` (
  `cd_id` integer NOT NULL,
  `artist_fk` integer NOT NULL,
  `title` varchar(96) NOT NULL,
  INDEX `cd_idx_artist_fk` (`artist_fk`),
  PRIMARY KEY (`cd_id`),
  CONSTRAINT `cd_fk_artist_fk` FOREIGN KEY (`artist_fk`) REFERENCES `artist` (`artist_id`) ON DELETE CASCADE ON UPDATE CASCADE
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
SET foreign_key_checks=1