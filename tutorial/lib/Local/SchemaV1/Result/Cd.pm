package Local::SchemaV1::Result::Cd;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('cd');
__PACKAGE__->add_columns(
  'cdid' => {
    data_type => 'integer',
  },
  'artist' => {
    data_type => 'integer',
  },
  'title' => {
    data_type => 'varchar',
    size => '96',
  });

__PACKAGE__->set_primary_key('cdid');
__PACKAGE__->belongs_to('artist' => "Local::SchemaV1::Result::Artist");
__PACKAGE__->has_many('tracks' => "Local::SchemaV1::Result::Track");

1;
