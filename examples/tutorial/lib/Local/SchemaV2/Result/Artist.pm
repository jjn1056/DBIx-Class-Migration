package Local::SchemaV2::Result::Artist;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
  'artist_id' => {
    data_type => 'integer',
  },
  country_fk => {
    data_type => 'integer',
  },
  'name' => {
    data_type => 'varchar',
    size => '96',
  });

__PACKAGE__->set_primary_key('artist_id');

__PACKAGE__->has_many(
  'cd_rs' => 'Local::SchemaV2::Result::Cd',
  {'foreign.artist_fk'=>'self.artist_id'});

__PACKAGE__->belongs_to(
  'has_country' => 'Local::SchemaV2::Result::Country',
  {'foreign.country_id'=>'self.country_fk'});


1;
