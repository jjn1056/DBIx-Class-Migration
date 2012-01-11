package Local::SchemaV1::Result::Artist;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
  'artist_id' => {
    data_type => 'integer',
  },
  'name' => {
    data_type => 'varchar',
    size => '96',
  });

__PACKAGE__->set_primary_key('artist_id');
__PACKAGE__->has_many(
  'cd_rs' => 'Local::SchemaV1::Result::Cd',
  {'foreign.artist_fk'=>'self.artist_id'});

1;
