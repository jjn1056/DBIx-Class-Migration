package Local::SchemaV3b::Result::Cd;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('cd');
__PACKAGE__->add_columns(
  'cdid' => {
    data_type => 'integer',
  },
  'title' => {
    data_type => 'varchar',
    size => '96',
  });

__PACKAGE__->set_primary_key('cdid');
__PACKAGE__->has_many('tracks' => "Local::SchemaV3b::Result::Track");

__PACKAGE__->has_many(
  'artist_cd_rs' => 'Local::SchemaV3b::Result::ArtistCd',
  {'foreign.cdfk'=>'self.cdid'});

__PACKAGE__->many_to_many(artists_cd => artist_cd_rs => 'artist');

1;
