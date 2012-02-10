package MusicBase::Schema::Result::Cd;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('cd');
__PACKAGE__->add_columns(
  'cd_id' => {
    data_type => 'integer',
  },
  'title' => {
    data_type => 'varchar',
    size => '96',
  });

__PACKAGE__->set_primary_key('cd_id');

__PACKAGE__->has_many(
  'track_rs' => 'MusicBase::Schema::Result::Track',
  {'foreign.cd_fk'=>'self.cd_id'});

__PACKAGE__->has_many(
  'artist_cd_rs' => 'MusicBase::Schema::Result::ArtistCd',
  {'foreign.cd_fk'=>'self.cd_id'});

__PACKAGE__->many_to_many(artists_cd => artist_cd_rs => 'artist');

1;

