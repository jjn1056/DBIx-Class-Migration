package Local::SchemaV3b::Result::ArtistCd;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('artist_cd');
__PACKAGE__->add_columns(
  artistfk => {
    data_type => 'integer',
    is_foreign_key => 1,
  },
  cdfk => {
    data_type => 'integer',
    is_foreign_key => 1,
  });

__PACKAGE__->set_primary_key('artistfk','cdfk');

__PACKAGE__->belongs_to(
  'artist' => "Local::SchemaV3b::Result::Artist",
  {'foreign.artistid'=>'self.artistfk'});

__PACKAGE__->belongs_to(
  'cd' => 'Local::SchemaV3b::Result::Cd',
  {'foreign.cdid'=>'self.cdfk'});

1;
