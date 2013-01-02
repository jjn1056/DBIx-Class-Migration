package Local::v2::Schema::ResultSet::Artist;
use base 'DBIx::Class::ResultSet';

sub has_more_than_two_cds {
  my $me = (my $self = shift)->current_source_alias;
  $self->search(
    {
      cd_count => {'>', 2},
    },
    {
      join=>['artist_cd_rs'],
      '+select'=> [ { count => 'artist_cd_rs.cd_fk' } ],
      '+as'=> ['cd_count'],
      group_by=>["$me.artist_id"],
    }
  );
}

1;
