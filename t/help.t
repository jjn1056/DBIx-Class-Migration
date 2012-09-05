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



MISSING_VERSION_EXCEPTION : {
  use lib 't/lib';
  use_ok 'Local::Schema';

  lives_ok { run_cli(argv => ["status","--schema_class",'Local::Schema']) }; 

  local $Local::Schema::VERSION = undef;

  throws_ok { run_cli(argv => ["status","--schema_class",'Local::Schema']) } 
    qr/A \$VERSION needs to be specified in the schema/;
}


done_testing;
