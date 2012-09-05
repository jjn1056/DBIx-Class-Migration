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



MISSING_VERSION_EXCEPTION : {
  use lib 't/lib';
  use_ok 'Local::Schema';

  lives_ok {
    DBIx::Class::Migration::Script->run_with_options(argv => ["status","--schema_class",'Local::Schema']);
  }; 

  local $Local::Schema::VERSION = undef;

  throws_ok {
    DBIx::Class::Migration::Script->run_with_options(argv => ["status","--schema_class",'Local::Schema']);
  } qr/A \$VERSION needs to be specified in your schema class Local\:\:Schema/;
}

done_testing;
