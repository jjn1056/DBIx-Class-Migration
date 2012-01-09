package Local::SchemaV3b::Result::Country;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('country');
__PACKAGE__->add_columns(
  'countryid' => {
    data_type => 'integer',
  },
  'code' => {
    data_type => 'char',
    size => '3',
  },
);

__PACKAGE__->set_primary_key('countryid');
__PACKAGE__->add_unique_constraint(['code']);
__PACKAGE__->has_many(
  'artists' => "Local::SchemaV3b::Result::Artist",
  {'foreign.countryfk'=>'self.countryid'});

1;
