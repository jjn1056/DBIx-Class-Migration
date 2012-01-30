;
BEGIN;

INSERT INTO artist_cd(artist_fk,cd_fk) select artist_fk,cd_id FROM cd;

COMMIT;
