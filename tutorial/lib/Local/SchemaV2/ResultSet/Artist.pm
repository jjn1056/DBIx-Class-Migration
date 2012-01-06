package Local::SchemaV2::ResultSet::Artist;
use base 'DBIx::Class::ResultSet';

sub has_more_than_two_cds {
  shift->search(
    {
      cd_count => {'>', 2},
    },
    {
      join=>['cds'],
      '+select'=> [ { count => 'cds.id' } ],
      '+as'=> ['cd_count'],
    }
  );
}

1;
