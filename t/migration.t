#!/usr/bin/env perl

use lib 't/lib';
use Test::Most;
use DBIx::Class::Migration;

ok my $migration = DBIx::Class::Migration->new(schema_class=>'Local::Schema'),
  'created migration with schema_class';

done_testing;
