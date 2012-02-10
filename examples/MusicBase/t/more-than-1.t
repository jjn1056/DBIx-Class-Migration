#!/usr/bin/env perl

use Test::Most;
use Test::DBIx::Class
  -schema_class=>'MusicBase::Schema',
  -fixture_class => '::Population',
  qw(Artist);

fixtures_ok ['all_tables'];

ok my $more_than_one_rs =  Artist->has_more_than_one_cds,
 'Got some artists';

is $more_than_one_rs->count, 1,
  'Got expected number of artists with more than one CD';

done_testing;

