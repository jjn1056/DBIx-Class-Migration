#!/usr/bin/env perl

use Test::Most;
use Test::Requires { 'Capture::Tiny' => 0.19 };
use DBIx::Class::Migration::Script;

plan skip_all => 'DBICM_TEST_HELP not set'
  unless $ENV{DBICM_TEST_HELP} || $ENV{AUTHOR_MODE};

ok(my $r = Capture::Tiny::capture_stdout {
  DBIx::Class::Migration::Script->run_with_options(argv =>["help"]);
});

like $r,
  qr/DBIx::Class::Migration::Script::Help - Summary of the commands/sm,
  'help command produces expected output';

done_testing;
