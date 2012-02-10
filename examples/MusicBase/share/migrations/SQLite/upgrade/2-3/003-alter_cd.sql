BEGIN;

CREATE TEMPORARY TABLE cd_temp_alter (
  cd_id INTEGER PRIMARY KEY NOT NULL,
  title varchar(96) NOT NULL
);

INSERT INTO cd_temp_alter SELECT cd_id, title FROM cd;

DROP TABLE cd;

CREATE TABLE cd (
  cd_id INTEGER PRIMARY KEY NOT NULL,
  title varchar(96) NOT NULL
);

INSERT INTO cd SELECT cd_id, title FROM cd_temp_alter;

DROP TABLE cd_temp_alter;

COMMIT;
