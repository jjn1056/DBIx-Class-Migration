#!/usr/bin/env perl

BEGIN {
  use Test::Most;
  plan skip_all => 'DBICM_TEST_MYSQL not set'
    unless $ENV{DBICM_TEST_MYSQL} || $ENV{AUTHOR_MODE};
}

use lib 't/lib';
use DBIx::Class::Migration;
use File::Spec::Functions 'catfile', 'catdir', 'splitpath';
use File::Path 'rmtree';
use Test::Requires qw(Test::mysqld);

ok(
  my $migration = DBIx::Class::Migration->new(
    schema_class=>'Local::Schema',
    db_sandbox_class=>'DBIx::Class::Migration::MySQLSandbox'),
  'created migration with schema_class');

isa_ok(
  my $schema = $migration->schema, 'Local::Schema',
  'got a reasonable looking schema');

is(
  DBIx::Class::Migration::_infer_database_from_schema($schema),
  'MySQL',
  'can correctly infer a database DBD');

$migration->prepare;

ok(
  (my $target_dir = $migration->target_dir),
  'got a good target directory');

ok -d catfile($target_dir, 'fixtures'), 'got fixtures';
ok -e catfile($target_dir, 'fixtures','1','conf','all_tables.json'), 'got the all_tables.json';
ok -d catfile($target_dir, 'migrations'), 'got migrations';
ok -e catfile($target_dir, 'migrations','MySQL','deploy','1','001-auto.sql'), 'found DDL';

open(
  my $perl_run,
  ">",
  catfile($target_dir, 'migrations', 'MySQL', 'deploy', '1', '002-artists.pl')
) || die "Cannot open: $!";

print $perl_run <<'END';

use Test::Most;
use DBIx::Class::Migration::RunScript;

migrate {
  my $self = shift;
  if($self->set_has_fixtures('all_tables')) {
    TODO: {
      local $TODO = 'Perl >= 5.18 stringifies %ENV values' if $] ge '5.018';
      lives_ok { $self->populate('all_tables') } "->populate('all_tables')";
    }
  } else {
    $self->schema
      ->resultset('Country')
      ->populate([
        ['code'],
        ['bel'],
        ['deu'],
        ['fra'],
      ]);

    TODO: {
      local $TODO = 'Perl >= 5.18 stringifies %ENV values' if $] ge '5.018';
      lives_ok { $self->dump('all_tables') } "->dump('all_tables')";
      ok $self->set_has_fixtures('all_tables'),
        'Fixture Set exists!';
    }
  }

};

END
close($perl_run);

$migration->install;

ok $schema->resultset('Country')->find({code=>'fra'}),
  'got some previously inserted data';

TODO: {
  local $TODO = 'Perl >= 5.18 stringifies %ENV values' if $] ge '5.018';
  ok -e catfile($target_dir, 'fixtures','1','all_tables','country','1.fix'),
    'found a fixture from runscript dump';
}

rmtree catfile($target_dir, 'fixtures','1','all_tables');

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

  ok( my $migration = DBIx::Class::Migration->new(
    schema_class=>'Local::Schema',
    db_sandbox_class=>'DBIx::Class::Migration::MySQLSandbox'),
  'created migration with schema_class');

  $migration->install;

  TODO: {
    local $TODO = 'Perl >= 5.18 stringifies %ENV values' if $] ge '5.018';
    ok $schema->resultset('Country')->find({code=>'fra'}),
      'got some previously inserted data';
  }

  $migration->delete_table_rows;
  $migration->populate('all_tables');

  ok $schema->resultset('Country')->find({code=>'bel'}),
    'got some previously inserted data';

  SCOPE_FOR_ALREADY_RUNNING: {

    ## The database is still running, lets make sure we can connect
    ## and use it without generating an error
    
    SKIP: {
      skip "Test::mysqld not patched yet", 3
        unless (eval qq{use Test::mysqld 0.15; 1} || 0);

      ok( my $migration = DBIx::Class::Migration->new(
        schema_class=>'Local::Schema',
        db_sandbox_class=>'DBIx::Class::Migration::MySQLSandbox'),
        'created migration with schema_class 3');

      isa_ok(
        my $schema = $migration->schema, 'Local::Schema',
        'got a reasonable looking schema');

      ok $schema->resultset('Country')->find({code=>'fra'}),
        'got some previously inserted data';
    }
  }

  my ($volume,$directories,$file) =
    splitpath($migration->db_sandbox->test_mysqld->my_cnf->{socket});
    
  rmtree $directories
    if ($directories && $file);  ## check to make sure we don't rmtree root

  $migration = undef;

  RESTORE_EXISTING_NOT_RUNNING: {

    ## The sandbox exists, but the db is NOT running and the
    ## socket path is gone;

    SKIP: {
      skip "Test::mysqld not patched yet", 3
        unless (eval qq{use Test::mysqld 0.15; 1} || 0);

      ok( my $migration = DBIx::Class::Migration->new(
        schema_class=>'Local::Schema',
        db_sandbox_class=>'DBIx::Class::Migration::MySQLSandbox'),
        'created migration with schema_class 4');

      isa_ok(
        my $schema = $migration->schema, 'Local::Schema',
        'got a reasonable looking schema');

      ok $schema->resultset('Country')->find({code=>'fra'}),
        'got some previously inserted data';
    }
  }

}

SCOPE_FOR_PARALLEL_TEMP: {

    ok( my $migration1 = DBIx::Class::Migration->new(
      schema_class=>'Local::Schema',
      db_sandbox_builder_class => 'DBIx::Class::Migration::TempDirSandboxBuilder',
      db_sandbox_class=>'DBIx::Class::Migration::MySQLSandbox'),
        'created migration with schema_class in temp 1');

    $migration1->install;

    ok( my $migration2 = DBIx::Class::Migration->new(
      schema_class=>'Local::Schema',
      db_sandbox_builder_class => 'DBIx::Class::Migration::TempDirSandboxBuilder',
      db_sandbox_class=>'DBIx::Class::Migration::MySQLSandbox'),
        'created migration with schema_class in temp 2');

    $migration2->install;

    ok( my $migration3 = DBIx::Class::Migration->new(
      schema_class=>'Local::Schema',
      db_sandbox_builder_class => 'DBIx::Class::Migration::TempDirSandboxBuilder',
      db_sandbox_class=>'DBIx::Class::Migration::MySQLSandbox'),
        'created migration with schema_class in temp 3');

    $migration3->install;
}

done_testing;

END {
  rmtree catfile($cleanup_dir, 'migrations');
  rmtree catfile($cleanup_dir, 'fixtures');
  rmtree catfile($cleanup_dir, 'local-schema');
}

