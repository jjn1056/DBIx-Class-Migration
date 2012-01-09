-- Convert schema '/Users/johnn/Desktop/App-DBIx-Class-Migration/tutorial/share/migrations/_source/deploy/2/001-auto.yml' to '/Users/johnn/Desktop/App-DBIx-Class-Migration/tutorial/share/migrations/_source/deploy/3/001-auto.yml':;

;
BEGIN;

INSERT INTO artist_cd(artistfk,cdfk) select artist,cdid FROM cd;

COMMIT;

