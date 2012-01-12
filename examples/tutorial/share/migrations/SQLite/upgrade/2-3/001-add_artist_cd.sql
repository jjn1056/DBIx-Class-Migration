-- Convert schema '/Users/johnn/Desktop/App-DBIx-Class-Migration/tutorial/share/migrations/_source/deploy/2/001-auto.yml' to '/Users/johnn/Desktop/App-DBIx-Class-Migration/tutorial/share/migrations/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE artist_cd (
  artist_fk integer NOT NULL,
  cd_fk integer NOT NULL,
  PRIMARY KEY (artist_fk, cd_fk),
  FOREIGN KEY(artist_fk) REFERENCES artist(artist_id),
  FOREIGN KEY(cd_fk) REFERENCES cd(cd_id)
);

;
CREATE INDEX artist_cd_idx_artist_fk ON artist_cd (artist_fk);

;
CREATE INDEX artist_cd_idx_cd_fk ON artist_cd (cd_fk);

COMMIT;

