-- Convert schema '/Users/johnn/Desktop/App-DBIx-Class-Migration/tutorial/share/migrations/_source/deploy/2/001-auto.yml' to '/Users/johnn/Desktop/App-DBIx-Class-Migration/tutorial/share/migrations/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE artist_cd (
  artistfk integer NOT NULL,
  cdfk integer NOT NULL,
  PRIMARY KEY (artistfk, cdfk),
  FOREIGN KEY(artistfk) REFERENCES artist(artistid),
  FOREIGN KEY(cdfk) REFERENCES cd(cdid)
);

;
CREATE INDEX artist_cd_idx_artistfk ON artist_cd (artistfk);

;
CREATE INDEX artist_cd_idx_cdfk ON artist_cd (cdfk);

COMMIT;

