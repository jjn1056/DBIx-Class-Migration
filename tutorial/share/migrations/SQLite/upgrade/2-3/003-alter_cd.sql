
BEGIN;

CREATE TEMPORARY TABLE cd_temp_alter (
  cdid INTEGER PRIMARY KEY NOT NULL,
  title varchar(96) NOT NULL
);

;
INSERT INTO cd_temp_alter SELECT cdid, title FROM cd;

DROP TABLE cd;

CREATE TABLE cd (
  cdid INTEGER PRIMARY KEY NOT NULL,
  title varchar(96) NOT NULL
);

;
INSERT INTO cd SELECT cdid, title FROM cd_temp_alter;

DROP TABLE cd_temp_alter;

COMMIT;

