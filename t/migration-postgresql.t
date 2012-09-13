#!/usr/bin/env perl

BEGIN {
  use Test::Most;
  plan skip_all => 'DBICM_TEST_PG not set'
    unless $ENV{DBICM_TEST_PG} || $ENV{AUTHOR_MODE};
}

use lib 't/lib';
use DBIx::Class::Migration;
use File::Spec::Functions 'catfile';
use File::Path 'rmtree';
use Test::Requires qw(Test::postgresql);

ok(
  my $migration = DBIx::Class::Migration->new(
    schema_class=>'Local::Schema',
    db_sandbox_class=>'DBIx::Class::Migration::PostgresqlSandbox'),
  'created migration with schema_class');

isa_ok(
  my $schema = $migration->schema, 'Local::Schema',
  'got a reasonable looking schema');

like(
  ($migration->_build_schema_args)->[0], qr/template1/,
  'generated schema_args seem ok');

is(
  DBIx::Class::Migration::_infer_database_from_schema($schema),
  'PostgreSQL',
  'can correctly infer a database DBD');

$migration->prepare;

ok(
  (my $target_dir = $migration->target_dir),
  'got a good target directory');

ok -d catfile($target_dir, 'fixtures'), 'got fixtures';
ok -e catfile($target_dir, 'fixtures','1','conf','all_tables.json'), 'got the all_tables.json';
ok -d catfile($target_dir, 'migrations'), 'got migrations';
ok -e catfile($target_dir, 'migrations','PostgreSQL','deploy','1','001-auto.sql'), 'found DDL';

open(
  my $perl_run,
  ">",
  my $install_artists = catfile($target_dir, 'migrations', 'PostgreSQL', 'deploy', '1', '002-artists.pl')
) || die "Cannot open: $!";

print $perl_run <<END;
  sub {
    my \$schema = shift;
    \$schema->resultset('Country')
      ->populate([
      ['code'],
      ['bel'],
      ['deu'],
      ['fra'],
    ]);
  };
END

close($perl_run);

$migration->install;

ok $schema->resultset('Country')->find({code=>'bel'}),
  'got some previously inserted data';

$migration->dump_all_sets;

ok -e catfile($target_dir, 'fixtures','1','all_tables','country','1.fix'),
  'found a fixture';

rmtree catfile($target_dir, 'fixtures','1','all_tables');

$migration->dump_named_sets('all_tables');

ok -e catfile($target_dir, 'fixtures','1','all_tables','country','1.fix'),
  'found a fixture';

$migration->delete_table_rows;
$migration->populate('all_tables');

ok $schema->resultset('Country')->find({code=>'fra'}),
  'got some previously inserted data';

$migration->drop_tables;

my $cleanup_dir = $migration->target_dir;

$migration = undef;

NEW_SCOPE_FOR_SCHEMA: {

  ## This tests to make sure we can just connect and start a sandbox
  ## against an existing setup

  ok( my $migration = DBIx::Class::Migration->new(
    schema_class=>'Local::Schema',
    db_sandbox_class=>'DBIx::Class::Migration::PostgresqlSandbox'),
  'created migration with schema_class #2');

  $migration->install;

  ok $schema->resultset('Country')->find({code=>'fra'}),
    'got some previously inserted data';

  $migration->delete_table_rows;
  $migration->populate('all_tables');

  ok $schema->resultset('Country')->find({code=>'bel'}),
    'got some previously inserted data';

  SCOPE_FOR_ALREADY_RUNNING: {

    ## The database is still running, lets make sure we can connect
    ## and use it

    ok( my $migration = DBIx::Class::Migration->new(
      schema_class=>'Local::Schema',
      db_sandbox_class=>'DBIx::Class::Migration::PostgresqlSandbox'),
      'created migration with schema_class #3');

    isa_ok(
      my $schema = $migration->schema, 'Local::Schema',
      'got a reasonable looking schema');

    ok $schema->resultset('Country')->find({code=>'fra'}),
      'got some previously inserted data';

  }
}

TEST_SEQUENCE_RESTORE: {

  ## Now lets test for the Postgresql Sequence Problem

  ok( my $migration = DBIx::Class::Migration->new(
    schema_class=>'Local::Schema',
    db_sandbox_class=>'DBIx::Class::Migration::PostgresqlSandbox'),
  'created migration with schema_class #3');

  ## First we are going to blow away the database from previous tests

  $migration->drop_tables;
  unlink $install_artists || 
    die "Can't delete $install_artists : $@";

  ## Next, install version one and populate the countries
  ## fixture set
  
  $migration->install;
  $migration->populate('all_tables');

  ## Make sure we got country data
  
  isa_ok(
    my $schema = $migration->schema, 'Local::Schema',
    'got a reasonable looking schema');

    ok $schema->resultset('Country')->find({code=>'fra'}),
      'got some previously inserted data';

  ## Since we populated the Country table from fixtures, it is possible that
  ## the sequences which control the PK Serial type are no longer telling us
  ## the right info.  In this case we'd expect an insert into Country (which
  ## has a SERIAL PK) to explode.  This sequence gets set correctly in newer
  ## versions of DBIC:Fixtures (=>1.001016)
  
  ok my $china = $schema->resultset('Country')->create({code=>'prc'}),
    'created the china country';
}

done_testing;

END {
  rmtree catfile($cleanup_dir, 'migrations');
  rmtree catfile($cleanup_dir, 'fixtures');
  rmtree catfile($cleanup_dir, 'local-schema');
}

