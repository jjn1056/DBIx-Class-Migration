package Local::SchemaV3b::Result::Country;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('country');
__PACKAGE__->add_columns(
  'country_id' => {
    data_type => 'integer',
  },
  'code' => {
    data_type => 'char',
    size => '3',
  });

__PACKAGE__->set_primary_key('country_id');
__PACKAGE__->add_unique_constraint(['code']);
__PACKAGE__->has_many(
  'artist_rs' => "Local::SchemaV3b::Result::Artist",
  {'foreign.country_fk'=>'self.country_id'});

1;
