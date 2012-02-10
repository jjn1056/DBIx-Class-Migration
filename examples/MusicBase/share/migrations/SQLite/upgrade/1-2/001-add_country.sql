BEGIN;

;
CREATE TABLE country (
  country_id INTEGER PRIMARY KEY NOT NULL,
  name varchar(96) NOT NULL
);

CREATE UNIQUE INDEX country_name ON country (name);

;
COMMIT;
