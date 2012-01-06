BEGIN;

CREATE TEMPORARY TABLE country_temp_alter (
  countryid INTEGER PRIMARY KEY NOT NULL,
  code char(3) NOT NULL
);

-- Match to current data
INSERT INTO country_temp_alter SELECT countryid, 'can' FROM country where name='Canada';
INSERT INTO country_temp_alter SELECT countryid, 'usa' FROM country where name='USA';
INSERT INTO country_temp_alter SELECT countryid, 'mex' FROM country where name='Mexico';
-- End Match

;
DROP TABLE country;

CREATE TABLE country (
  countryid INTEGER PRIMARY KEY NOT NULL,
  code char(3) NOT NULL
);

CREATE UNIQUE INDEX country_code02 ON country (code);

INSERT INTO country SELECT countryid, code FROM country_temp_alter;

DROP TABLE country_temp_alter;

COMMIT;

