use Test::Most tests=>16;

BEGIN {
  use_ok 'DBIx::Class::Migration';
  use_ok 'DBIx::Class::Migration::SchemaLoader';
  use_ok 'DBIx::Class::Migration::Script';
  use_ok 'DBIx::Class::Migration::Population';
  use_ok 'DBIx::Class::Migration::SqliteSandbox';
  use_ok 'DBIx::Class::Migration::MySQLSandbox';
  use_ok 'DBIx::Class::Migration::PostgresqlSandbox';
  use_ok 'Catalyst::TraitFor::Model::DBIC::Schema::FromMigration::_MigrationHelper';
  use_ok 'Catalyst::TraitFor::Model::DBIC::Schema::FromMigration';
  use_ok 'DBIx::Class::Migration::Sandbox';
  use_ok 'DBIx::Class::Migration::ShareDirBuilder';
  use_ok 'DBIx::Class::Migration::TempDirBuilder';
  use_ok 'Test::DBIx::Class::FixtureCommand::Population';
  use_ok 'DBIx::Class::Migration::TargetDirSandboxBuilder';
  use_ok 'DBIx::Class::Migration::TempDirSandboxBuilder';
  use_ok 'DBIx::Class::Migration::RunScript';
}



