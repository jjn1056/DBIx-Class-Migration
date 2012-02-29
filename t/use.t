use Test::Most tests=>16;
use Class::Load 'try_load_class';
 
BEGIN {

  use_ok 'DBIx::Class::Migration';
  use_ok 'DBIx::Class::Migration::SchemaLoader';
  use_ok 'DBIx::Class::Migration::Script';
  use_ok 'DBIx::Class::Migration::SqliteSandbox';
  use_ok 'Catalyst::TraitFor::Model::DBIC::Schema::FromMigration::_MigrationHelper';
  use_ok 'Catalyst::TraitFor::Model::DBIC::Schema::FromMigration';
  use_ok 'DBIx::Class::Migration::Sandbox';
  use_ok 'DBIx::Class::Migration::ShareDirBuilder';
  use_ok 'DBIx::Class::Migration::TempDirBuilder';
  use_ok 'Test::DBIx::Class::FixtureCommand::Population';
  use_ok 'DBIx::Class::Migration::TargetDirSandboxBuilder';
  use_ok 'DBIx::Class::Migration::TempDirSandboxBuilder';
  use_ok 'DBIx::Class::Migration::RunScript';

  SKIP: {
    skip "Don't test population classes", 1
      unless try_load_class('Test::DBIx::Class');
    use_ok 'DBIx::Class::Migration::Population';
  };

  SKIP: {
    skip "Don't test mysql classes", 1
      unless try_load_class('Test::mysqld');
      use_ok 'DBIx::Class::Migration::MySQLSandbox';
  };

  SKIP: {
    skip "Don't test pg classes", 1
      unless try_load_class('Test::postgresql');
    use_ok 'DBIx::Class::Migration::PostgresqlSandbox';
  };

}



