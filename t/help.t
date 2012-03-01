#!/usr/bin/env perl

use Test::Most;
use Test::Requires 'Test::Trap';
use DBIx::Class::Migration::Script;

sub run_cli {
  DBIx::Class::Migration::Script->run_with_options(@_);
}

my @r = trap { run_cli(argv =>["help"]); };

like $trap->stdout,
  qr/^Commands:.*^\s+help:.*^\s+version:.*^\s+status:/sm,
  'help command produces output';

done_testing;
