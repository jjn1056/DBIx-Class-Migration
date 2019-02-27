use strict;
use warnings;
use lib 't/lib';
use Test::Most;
use DBIx::Class::Migration;
use Local::Schema;
use File::Temp 'tempdir';

my $dir = tempdir(DIR => 't', CLEANUP => 1);

## Create an in-memory sqlite version of the test schema
ok my $schema = Local::Schema->connect('dbi:SQLite::memory:');

# SQL_IDENTIFIER_QUOTE_CHAR
$schema->storage->sql_maker->quote_char($schema->storage->dbh->get_info(29));

$schema->deploy;

## Connect a DBIC migration to that
ok(
  my $migration = DBIx::Class::Migration->new(
    schema => $schema,
    target_dir => $dir,
  )
);

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
