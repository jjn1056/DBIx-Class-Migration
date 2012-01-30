package Local::SchemaV3a::Result::Country;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('country');
__PACKAGE__->add_columns(
  'country_id' => {
    data_type => 'integer',
  },
  'name' => {
    data_type => 'varchar',
    size => '96',
  });

__PACKAGE__->set_primary_key('country_id');
__PACKAGE__->add_unique_constraint(['name']);
__PACKAGE__->has_many(
  'artist_rs' => "Local::SchemaV3a::Result::Artist",
  {'foreign.country_fk'=>'self.country_id'});

1;
