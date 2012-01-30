package Local::SchemaV3b::Result::ArtistCd;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('artist_cd');
__PACKAGE__->add_columns(
  artist_fk => {
    data_type => 'integer',
  },
  cd_fk => {
    data_type => 'integer',
  });

__PACKAGE__->set_primary_key('artist_fk','cd_fk');

__PACKAGE__->belongs_to(
  'artist' => "Local::SchemaV3b::Result::Artist",
  {'foreign.artist_id'=>'self.artist_fk'});

__PACKAGE__->belongs_to(
  'cd' => 'Local::SchemaV3b::Result::Cd',
  {'foreign.cd_id'=>'self.cd_fk'});

1;
