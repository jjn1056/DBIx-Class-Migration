package Local::Schema::Result::ViewTest;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table('viewtest');

__PACKAGE__->add_columns(
  artist_id => {
    data_type => 'integer',
  },
  artist_name => {
    data_type => 'varchar',
    size => '96',
  },
  cd_id => {
    data_type => 'integer',
  },
  cd_title => {
    data_type => 'varchar',
    size => '96',
  },
);

# Don't attempt to deploy the view to the database. Not all views are virtual, but they
# should all be ignored when dumping fixtures (probably).
__PACKAGE__->result_source_instance->is_virtual(1);
__PACKAGE__->result_source_instance->view_definition(q[
  SELECT
    a.id        as artist_id,
    a.name      as artist_name,
    cd.id       as cd_id,
    cd.title    as cd_title,
  FROM artist a
    INNER JOIN artist_cd as acd ON a.id = acd.artist_fk
    INNER JOIN cd ON acd.cd_fk = cd.id
  ORDER BY a.name, cd.title
]);
