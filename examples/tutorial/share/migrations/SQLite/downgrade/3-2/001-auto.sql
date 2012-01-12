-- Convert schema '/Users/johnn/Desktop/DBIx-Class-Migration/examples/tutorial/share/migrations/_source/deploy/3/001-auto.yml' to '/Users/johnn/Desktop/DBIx-Class-Migration/examples/tutorial/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE cd ADD COLUMN artist_fk integer NOT NULL;

;
CREATE INDEX cd_idx_artist_fk ON cd (artist_fk);

;
DROP INDEX track_fk_cd_fk;

;
DROP TABLE artist_cd;

;

COMMIT;

