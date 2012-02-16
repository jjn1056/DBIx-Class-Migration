{
  name => 'MusicBase::Web',
  default_view => 'HTML',
  disable_component_resolution_regex_fallback => 1,
  'Controller::Root' => {
    namespace => '',
  },
  'Model::Schema' => {
    traits => ['FromMigration'],
    schema_class => 'MusicBase::Schema',
    extra_migration_args => {
      db_sandbox_class => 'DBIx::Class::Migration::MySQLSandbox'},
    install_if_needed => {
      default_fixture_sets => ['all_tables']},
  },
  'View::HTML' => {
    INCLUDE_PATH => [ '__path_to(share,html)__' ],
    TEMPLATE_EXTENSION => '.tt',
  },
};
