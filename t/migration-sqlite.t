#!/usr/bin/env perl

use lib 't/lib';
use Test::Most;
use DBIx::Class::Migration;
use File::Spec::Functions 'catfile';
use File::Path 'rmtree';

ok(
  my $migration = DBIx::Class::Migration->new(schema_class=>'Local::Schema'),
  'created migration with schema_class');

isa_ok(
  my $schema = $migration->schema, 'Local::Schema',
  'got a reasonable looking schema');

like(
  ($migration->_build_schema_args)->[0], qr/local-schema\.db$/,
  'generated schema_args seem ok');

is(
  DBIx::Class::Migration::_infer_database_from_schema($schema),
  'SQLite',
  'can correctly infer a database DBD');

$migration->prepare;

ok(
  (my $target_dir = $migration->target_dir),
  'got a good target directory');

ok -d catfile($target_dir, 'fixtures'), 'got fixtures';
ok -e catfile($target_dir, 'fixtures','1','conf','all_tables.json'), 'got the all_tables.json';
ok -d catfile($target_dir, 'migrations'), 'got migrations';
ok -e catfile($target_dir, 'migrations','SQLite','deploy','1','001-auto.sql'), 'found DDL';

open(
  my $perl_run,
  ">",
  catfile($target_dir, 'migrations', 'SQLite', 'deploy', '1', '002-artists.pl')
) || die "Cannot open: $!";

print $perl_run <<'END';

use DBIx::Class::Migration::RunScript;

builder {
  'SchemaLoader',
  sub {
    my $self = shift;
    $self->schema->resultset('Country')
      ->populate([
      ['code'],
      ['bel'],
      ['deu'],
      ['fra'],
    ]);
  };
};

END

close($perl_run);

$migration->install;

ok $schema->resultset('Country')->find({code=>'fra'}),
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

NEW_SCOPE_FOR_SCHEMA: {

  my $migration = DBIx::Class::Migration->new(
    schema_class=>'Local::Schema');
    
  $migration->install;

  ok $schema->resultset('Country')->find({code=>'fra'}),
    'got some previously inserted data';

  $migration->delete_table_rows;
  $migration->populate('all_tables');

  ok $schema->resultset('Country')->find({code=>'bel'}),
    'got some previously inserted data';

}

done_testing;

END {
  rmtree catfile($migration->target_dir, 'migrations');
  rmtree catfile($migration->target_dir, 'fixtures');
  unlink catfile($migration->target_dir, 'local-schema.db');
}
