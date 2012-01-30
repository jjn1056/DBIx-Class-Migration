use Test::Most tests=>5;

BEGIN {
  use_ok 'DBIx::Class::Migration';
  use_ok 'DBIx::Class::Migration::SchemaLoader';
  use_ok 'DBIx::Class::Migration::Script';
  use_ok 'DBIx::Class::Migration::Population';
  use_ok 'DBIx::Class::Migration::SqliteSandbox';
}

