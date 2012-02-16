{
  'Model::Schema' => {
    traits => ['FromMigration'],
    schema_class => 'MusicBase::Schema',
    extra_migration_args => {
      db_sandbox_builder_class => 'DBIx::Class::Migration::TempDirSandboxBuilder',
      db_sandbox_class => 'DBIx::Class::Migration::MySQLSandbox'},
    install_if_needed => {
      default_fixture_sets => ['all_tables']},
  }
};
