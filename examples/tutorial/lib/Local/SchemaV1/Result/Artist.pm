package Local::SchemaV1::Result::Artist;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
  'artistid' => {
    data_type => 'integer',
  },
  'name' => {
    data_type => 'varchar',
    size => '96',
  });

__PACKAGE__->set_primary_key('artistid');
__PACKAGE__->has_many('cds' => "Local::SchemaV1::Result::Cd");

1;
