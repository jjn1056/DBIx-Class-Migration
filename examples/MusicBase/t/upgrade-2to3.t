#!/usr/bin/env perl

use Test::Most;
use DBIx::Class::Migration::Population;
use Test::DBIx::Class
  -schema_class=>'MusicBase::Schema',
  qw(Artist Country);

plan skip_all => 'not correct schema version'
  if Schema->schema_version != 3;

(my $population = DBIx::Class::Migration::Population->new(
  schema=>Schema()))->populate('all_tables');

is Country->count, 6,
  'Correct Number of Tests';

ok my $artist = Artist->first,
  'Got one artist';

is $artist->has_country->code, 'can',
  'Oh Canada!';

is scalar($artist->artist_cds), 2,
  'has two cd';

done_testing;

