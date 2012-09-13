#!/usr/bin/env perl

## This is a test case used to try and replicate a reported issue with
## Postgresql, when we try to restore data from a fixture set and we
## populate a table that has FKs to another table we have not yet restored.

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

## Create the migration object and set it up for test

ok(
  my $migration = DBIx::Class::Migration->new(
    schema_class=>'Local::Schema',
    db_sandbox_class=>'DBIx::Class::Migration::PostgresqlSandbox'),
  'created migration with schema_class');

isa_ok(
  my $schema = $migration->schema, 'Local::Schema',
  'got a reasonable looking schema');

## Create the deployment files

$migration->prepare;

## install the database

$migration->install;

## Install some data

$schema->resultset('Country')
  ->populate([
    ['code'],
    ['bel'],
    ['deu'],
    ['fra'],
  ]);

my $artist1 = $schema->resultset('Artist')
  ->create({name=>'Artist1', has_country=>{code=>'fra'}});

  for($artist1->add_to_artist_cds({title=>'title1'})) {
    $_->add_to_tracks({title=>'track1'});
    $_->add_to_tracks({title=>'track2'});
    $_->add_to_tracks({title=>'track3'});
    $_->add_to_tracks({title=>'track4'});
  }

my $artist2 = $schema->resultset('Artist')
  ->create({name=>'Artist2', has_country=>{code=>'bel'}});

  for($artist2->add_to_artist_cds({title=>'title1'})) {
    $_->add_to_tracks({title=>'track1'});
    $_->add_to_tracks({title=>'track2'});
    $_->add_to_tracks({title=>'track3'});
    $_->add_to_tracks({title=>'track4'});
  }

## Create a fixture set

$migration->dump_named_sets('all_tables');

## Blow away the database

$migration->drop_tables;

## Reinstall the DB from scratch

$migration->install;

## populate the sets

$migration->populate('all_tables');

ok $schema->resultset('Country')->find({code=>'fra'}),
  'got some restored  data';

ok $schema->resultset('Artist')->find({name=>'Artist1'}),
  'got some restored  data';

## This time try just 'cleaning' existing tables
  
$migration->delete_table_rows;

$migration->populate('all_tables');

ok $schema->resultset('Country')->find({code=>'fra'}),
  'got some restored  data';

ok $schema->resultset('Artist')->find({name=>'Artist1'}),
  'got some restored  data';

done_testing;

END {
  my $cleanup_dir = $migration->target_dir;
  rmtree catfile($cleanup_dir, 'migrations');
  rmtree catfile($cleanup_dir, 'fixtures');
  rmtree catfile($cleanup_dir, 'local-schema');
}
