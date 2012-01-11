#!/usr/bin/env perl

use Test::Most;
use DBIx::Class::Migration::Population;
use Test::DBIx::Class
  -traits=>['Testmysqld'],
  -schema_class=>'Local::Schema',
  qw(Artist);

warn Schema()->schema_version;
warn Schema()->sources;

(my $population = DBIx::Class::Migration::Population->new(
  schema=>Schema()))->populate('all_tables');

ok my $mj = Artist->has_more_than_one_cds->first;

is $mj->name, "Michael Jackson";
is $mj->get_column('cd_count'), 2;

done_testing;

