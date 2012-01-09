package Local::SchemaV3b::Result::Artist;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('artist');

__PACKAGE__->add_columns(
  artistid => {
    data_type => 'integer',
  },
  countryfk => {
    data_type => 'integer',
    default_value => '1',
    is_foreign_key => 1,
  },
  name => {
    data_type => 'varchar',
    size => '96',
  });

__PACKAGE__->set_primary_key('artistid');

__PACKAGE__->has_many(
  'artist_cd_rs' => 'Local::SchemaV3b::Result::ArtistCd',
  {'foreign.artistfk'=>'self.artistid'});

__PACKAGE__->many_to_many(artist_cds => artist_cd_rs => 'cd');

__PACKAGE__->belongs_to(
  'has_country' => 'Local::SchemaV3b::Result::Country',
  {'foreign.countryid'=>'self.countryfk'});

1;
