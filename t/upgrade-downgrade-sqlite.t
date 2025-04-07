use strict;
use warnings;
use lib 't/lib';
use Test::Most;
use DBIx::Class::Migration;
use File::Spec::Functions 'catfile', 'catdir', 'rel2abs';
use File::Temp 'tempdir';

my $dir = tempdir(DIR => 't', CLEANUP => 1);

my ($target_dir, $schema_args);  # Outer Scope so we can reuse

SCHEMA_V1: {

  ok(
    my $migration = DBIx::Class::Migration->new(
      schema_class=>'Local::Schema',
      target_dir => $dir,
    ),
    'created migration with schema_class');

  $migration->prepare;

  isa_ok(
    my $schema = $migration->schema, 'Local::Schema',
   'got a reasonable looking schema');

  ok(
    ($target_dir = $migration->target_dir),
    'got a good target directory');


  $schema_args = $migration->schema_args;

  open(
    my $perl_run,
    ">",
    catfile($target_dir, 'migrations', 'SQLite', 'deploy', '1', '002-artists.pl')
  ) || die "Cannot open: $!";

  print $perl_run <<'END';

  use DBIx::Class::Migration::RunScript;
  use Test::Most;

  ok $ENV{DBIC_MIGRATION_TARGET_DIR};

  builder {
    'SchemaLoader',
    sub {
      my $self = shift;

      ## Add some countries
      $self->schema->resultset('Country')
        ->populate([
        ['code'],
        ['bel'],
        ['deu'],
        ['fra'],
      ]);

      ## And a few sample artists
      $self->schema->resultset('Artist')
        ->create({ name => 'Rocker One', country_fk => 1 });

      $self->schema->resultset('Artist')
        ->create({ name => 'Rocker Two', country_fk => 2 });
    };
  };

END

  close($perl_run);

  $migration->install;

  ok ((my $country = $schema->resultset('Country')->find({code=>'fra'})),
    'got some previously inserted data');

  ok ((my $rocker = $schema->resultset('Artist')->search({name=>'Rocker One'})->first),
    'got some previously inserted data');

  is $country->code, 'fra';
  is $rocker->name, 'Rocker One';

  $migration->dump_all_sets;

  ok -e catfile($target_dir, 'fixtures','1','all_tables','country','1.fix'),
    'found a fixture';
}

SCHEMA_V2: {

  ok(
    my $migration = DBIx::Class::Migration->new(
      schema_class=>'Local::v2::Schema',
      schema_args => $schema_args,
      target_dir => $dir,
    ),
    'created migration with schema_class and args');

  isa_ok(
    my $schema = $migration->schema, 'Local::v2::Schema',
   'got a reasonable looking schema');

  {
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, shift };
    $migration->prepare;

    ok scalar @warns == 0, "UTF handled correctly. No 'Wide character in print' warning.";
  }

  ## Lets massage the upgrade and downgrade files
  my $upgrade = catfile($target_dir, 'migrations', 'SQLite', 'upgrade', '1-2', '001-auto.sql');
  my $downgrade = catfile($target_dir, 'migrations', 'SQLite', 'downgrade', '2-1', '001-auto.sql');
  ok -e $upgrade, "found $upgrade"
    or diag "dbic_dh_args: ", Test::More::explain $migration->dbic_dh_args;
  ok -e $downgrade, "found $downgrade";
  open(my $upgrade_fh, ">", $upgrade )
    || die "Cannot open: $!";
  print $upgrade_fh <<'END';

;
BEGIN;

;
CREATE TEMPORARY TABLE artist_temp_alter (
  artist_id INTEGER PRIMARY KEY NOT NULL,
  country_fk integer NOT NULL,
  first_name varchar(96) NOT NULL,
  last_name varchar(96) NOT NULL,
  FOREIGN KEY (country_fk) REFERENCES country(country_id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
INSERT INTO artist_temp_alter( artist_id, country_fk, first_name, last_name) SELECT artist_id, country_fk, substr(name,0,7), substr(name,8) FROM artist;

;
DROP TABLE artist;

;
CREATE TABLE artist (
  artist_id INTEGER PRIMARY KEY NOT NULL,
  country_fk integer NOT NULL,
  first_name varchar(96) NOT NULL,
  last_name varchar(96) NOT NULL,
  FOREIGN KEY (country_fk) REFERENCES country(country_id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX artist_idx_country_fk02 ON artist (country_fk);

;
INSERT INTO artist SELECT artist_id, country_fk, first_name, last_name FROM artist_temp_alter;

;
DROP TABLE artist_temp_alter;

;

COMMIT;


END

  close($upgrade_fh);

  open(my $downgrade_fh, ">", $downgrade )
    || die "Cannot open: $!";

  print $downgrade_fh <<'END';

;
BEGIN;

;
CREATE TEMPORARY TABLE artist_temp_alter (
  artist_id INTEGER PRIMARY KEY NOT NULL,
  country_fk integer NOT NULL,
  name varchar(96) NOT NULL,
  FOREIGN KEY (country_fk) REFERENCES country(country_id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
INSERT INTO artist_temp_alter( artist_id, country_fk, name) SELECT artist_id, country_fk, first_name||' '||last_name FROM artist;

;
DROP TABLE artist;

;
CREATE TABLE artist (
  artist_id INTEGER PRIMARY KEY NOT NULL,
  country_fk integer NOT NULL,
  name varchar(96) NOT NULL,
  FOREIGN KEY (country_fk) REFERENCES country(country_id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX artist_idx_country_fk04 ON artist (country_fk);

;
INSERT INTO artist SELECT artist_id, country_fk, name FROM artist_temp_alter;

;
DROP TABLE artist_temp_alter;

;

COMMIT;

END

  close($downgrade_fh);

  $migration->upgrade;

  is $schema->resultset('Artist')->search({last_name=>'Two'})->first->last_name, 'Two';

  $migration->dump_all_sets;

  ok -e catfile($target_dir, 'fixtures','2','all_tables','country','1.fix'),
    'found a fixture for version 2 of the schema';

  $migration->downgrade;

}

CHECK_DOWNGRADE: {

  ok(
    my $migration = DBIx::Class::Migration->new(
      schema_class=>'Local::Schema',
      target_dir => $dir,
    ),
    'created migration with schema_class');

  isa_ok(
    my $schema = $migration->schema, 'Local::Schema',
   'got a reasonable looking schema');


  ok ((my $rocker = $schema->resultset('Artist')->search({name=>'Rocker One'})->first),
  'got some previously inserted data');

  is $rocker->name, 'Rocker One';

}

CHECK_TO_VERSION_FIXTURE: {
  # keep same fixtures, zap SQLite DB so start from fresh
  my $file = $schema_args->[0];
  $file =~ s#^(.*?:){2}##;
  ok unlink($file), "deleted db '$file' ok";
  require DBIx::Class::Migration::Script;
  local @ARGV = (
    '--schema_class' => 'Local::v2::Schema',
    '--to_version' => 1,
    '--target_dir' => $dir,
    'install'
  );
  ok(
    my $migration = DBIx::Class::Migration::Script->new_with_options,
    'created migration with lowered to_version');

  is $migration->to_version, 1, 'DH has correct version';
  is $migration->migration->build_dbic_fixtures_init_args->{config_dir},
    rel2abs(catdir($dir, qw(fixtures 1 conf))), 'DBICF has correct version';
  $migration->run;
}

done_testing;
