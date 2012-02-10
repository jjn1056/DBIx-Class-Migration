BEGIN;

CREATE TEMPORARY TABLE country_temp_alter (
  country_id INTEGER PRIMARY KEY NOT NULL,
  code char(3) NOT NULL
);

-- Match to current data
INSERT INTO country_temp_alter SELECT country_id, 'can' FROM country where name='Canada';
INSERT INTO country_temp_alter SELECT country_id, 'usa' FROM country where name='USA';
INSERT INTO country_temp_alter SELECT country_id, 'mex' FROM country where name='Mexico';
-- End Match
;
DROP TABLE country;

CREATE TABLE country (
  country_id INTEGER PRIMARY KEY NOT NULL,
  code char(3) NOT NULL
);

CREATE UNIQUE INDEX country_code02 ON country (code);

INSERT INTO country SELECT country_id, code FROM country_temp_alter;

DROP TABLE country_temp_alter;

COMMIT;

