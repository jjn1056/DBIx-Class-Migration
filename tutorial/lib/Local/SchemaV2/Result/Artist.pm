package Local::SchemaV2::Result::Artist;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
  'artistid' => {
    data_type => 'integer',
  },
  countryfk => {
    data_type => 'integer',
    default_value => '1',
    is_foreign_key => 1,
  },
  'name' => {
    data_type => 'varchar',
    size => '96',
  });

__PACKAGE__->set_primary_key('artistid');
__PACKAGE__->has_many('cds' => "Local::SchemaV2::Result::Cd");
__PACKAGE__->belongs_to('has_country' => 'Local::SchemaV2::Result::Country', {'foreign.countryid'=>'self.countryfk'});

1;
