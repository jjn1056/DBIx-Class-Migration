package Local::v2::Schema::Result::Artist;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('artist');

__PACKAGE__->add_columns(
  artist_id => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  country_fk => {
    data_type => 'integer',
    is_foreign_key => 1,
  },
  first_name => {
    data_type => 'varchar',
    size => '96',
  },
  last_name => {
    data_type => 'varchar',
    size => '96',
  });

__PACKAGE__->set_primary_key('artist_id');

__PACKAGE__->has_many(
  'artist_cd_rs' => 'Local::v2::Schema::Result::ArtistCd',
  {'foreign.artist_fk'=>'self.artist_id'});

__PACKAGE__->many_to_many(artist_cds => artist_cd_rs => 'cd');

__PACKAGE__->belongs_to(
  'has_country' => 'Local::v2::Schema::Result::Country',
  {'foreign.country_id'=>'self.country_fk'});

1;
