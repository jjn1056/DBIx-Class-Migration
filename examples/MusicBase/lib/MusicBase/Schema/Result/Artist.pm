package MusicBase::Schema::Result::Artist;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('artist');

__PACKAGE__->add_columns(
  artist_id => {
    data_type => 'integer',
  },
  country_fk => {
    data_type => 'integer',
  },
  name => {
    data_type => 'varchar',
    size => '96',
  });

__PACKAGE__->set_primary_key('artist_id');

__PACKAGE__->belongs_to(
  'has_country' => 'MusicBase::Schema::Result::Country',
  {'foreign.country_id'=>'self.country_fk'});

__PACKAGE__->has_many(
  'artist_cd_rs' => 'MusicBase::Schema::Result::ArtistCd',
  {'foreign.artist_fk'=>'self.artist_id'});

__PACKAGE__->many_to_many(artist_cds => artist_cd_rs => 'cd');

1;

