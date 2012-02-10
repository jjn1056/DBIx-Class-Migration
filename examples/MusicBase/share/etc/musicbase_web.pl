{
  name => 'MusicBase::Web',
  using_frontend_proxy => 1,
  default_view => 'HTML',
  disable_component_resolution_regex_fallback => 1,
  'Controller::Root' => {
    namespace => '',
  },
  'Model::Schema' => {
    schema_class => 'MusicBase::Schema',
    connect_info => {
      dsn => 'DBI:mysql:test;mysql_socket=__path_to(share,musicbase-schema,tmp,mysql.sock)__',
      user => 'root',
      password => '',
    }
  },
  'View::HTML' => {
    INCLUDE_PATH => [ '__path_to(share,html)__' ],
    TEMPLATE_EXTENSION => '.tt',
  },
};
