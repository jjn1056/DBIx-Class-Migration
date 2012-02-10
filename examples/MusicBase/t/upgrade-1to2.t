#!/usr/bin/env perl

use Test::Most;
use DBIx::Class::Migration::Population;
use Test::DBIx::Class
  -schema_class=>'MusicBase::Schema',
  qw(Artist Country);

plan skip_all => 'not correct schema version'
  if Schema->schema_version != 2;

(my $population = DBIx::Class::Migration::Population->new(
  schema=>Schema()))->populate('all_tables');

is Country->count, 3, 'Correct Number of Countries';
ok Artist->first->has_country, 'Artist has a country';

done_testing;
