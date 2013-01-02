package Local::v2::Schema::Result::Cd;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('cd');
__PACKAGE__->add_columns(
  'cd_id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'title' => {
    data_type => 'varchar',
    size => '96',
  });

__PACKAGE__->set_primary_key('cd_id');
__PACKAGE__->has_many('tracks' => "Local::v2::Schema::Result::Track");

__PACKAGE__->has_many(
  'artist_cd_rs' => 'Local::v2::Schema::Result::ArtistCd',
  {'foreign.cd_fk'=>'self.cd_id'});

__PACKAGE__->many_to_many(artists_cd => artist_cd_rs => 'artist');

1;
