-- Convert schema '/Users/johnn/Desktop/App-DBIx-Class-Migration/tutorial/share/migrations/_source/deploy/1/001-auto.yml' to '/Users/johnn/Desktop/App-DBIx-Class-Migration/tutorial/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE country (
  country_id INTEGER PRIMARY KEY NOT NULL,
  name varchar(96) NOT NULL
);

COMMIT;

