package DBIx::Class::Migration::RunScript::Trait::SchemaLoader;

use Moose::Role;
use DBIx::Class::Schema::Loader;
use DBIx::Class::Migration::SchemaLoader;

requires 'dbh';

has 'schema' => (
  is=>'ro',
  lazy_build=>1);

sub _build_schema {
  my $dbh = (my $self = shift)->dbh;
  my $name = DBIx::Class::Migration::SchemaLoader::_as_unique_ns('DBIx::Class::Migration::LoadedSchema');
  return DBIx::Class::Schema::Loader::make_schema_at(
    $name, {DBIx::Class::Migration::SchemaLoader::opts}, [ sub {$dbh} ]);
}

1;
