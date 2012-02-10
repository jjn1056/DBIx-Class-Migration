package MusicBase::Schema::ResultSet::Artist;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

sub has_more_than_one_cds {
  my $me = (my $self = shift)->current_source_alias;
  $self->search(
    {},
    {
      join=>['artist_cd_rs'],
      '+select'=> [ { count => 'artist_cd_rs.cd_fk', -as => 'cd_count'} ],
      '+as'=> ['cd_count'],
      group_by=>["$me.artist_id"],
      having => { cd_count => \'> 1' }
    }
  );
}

1;

