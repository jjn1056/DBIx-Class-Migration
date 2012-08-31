#!/usr/bin/env perl

use Test::Most;
use Test::Requires 'Capture::Tiny';
use DBIx::Class::Migration::Script;

ok(my $r = Capture::Tiny::capture_stdout {
  DBIx::Class::Migration::Script->run_with_options(argv =>["help"]);
});

like $r,
  qr/DBIx::Class::Migration::Script::Help - Summary of the commands/sm,
  'help command produces expected output';

done_testing;
