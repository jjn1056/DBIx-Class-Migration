package Local::SchemaV2::Result::Country;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('country');
__PACKAGE__->add_columns(
  'countryid' => {
    data_type => 'integer',
  },
  'name' => {
    data_type => 'varchar',
    size => '96',
  });

__PACKAGE__->set_primary_key('countryid');
__PACKAGE__->has_many('artists' => "Local::SchemaV2::Result::Artist", {'foreign.countryfk'=>'self.countryid'});

1;
