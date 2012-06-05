#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';
use Test::Most;
use DBIx::Class::Migration;
use File::Spec::Functions 'catfile';
use File::Path 'rmtree';
use Local::Schema;

## Create an in-memory sqlite version of the test schema
(my $schema = Local::Schema->connect('dbi:SQLite::memory:'))
  ->deploy;

## Connect a DBIC migration to that
ok my $migration = DBIx::Class::Migration->new(schema => $schema);

## Verify that the connected schema is missing the version storage meta-table

ok my $dbic_dh = $migration->dbic_dh;

is(
  $dbic_dh->schema_version, 1,
    'schema version ok');

is(
  $dbic_dh->version_storage_is_installed, undef,
    'version storage not yet installed');


## Install the version storage and set the version
$migration->prepare;
$migration->install_version_storage;

## Make sure the version is right and the meta table exists

ok(
  $dbic_dh->version_storage_is_installed,
  'version storage installed ok');

is(
  $dbic_dh->database_version, $dbic_dh->schema_version,
  'database version and schema version match');

done_testing;

END {
  rmtree catfile($migration->target_dir, 'migrations');
  rmtree catfile($migration->target_dir, 'fixtures');
  unlink catfile($migration->target_dir, 'local-schema.db');
}
