use Test::Most tests=>3;

BEGIN {
  use_ok 'DBIx::Class::Migration';
  use_ok 'DBIx::Class::Migration::SchemaLoader';
  use_ok 'DBIx::Class::Migration::Script';
}

