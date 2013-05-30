#!/usr/bin/env perl

use Test::Most;
use DBIx::Class::Migration::Script;

use lib 't/lib';
use_ok 'Local::Schema';

lives_ok {
  DBIx::Class::Migration::Script->run_with_options(argv => ["status","--schema_class",'Local::Schema']);
}; 

local $Local::Schema::VERSION = undef;

throws_ok {
  DBIx::Class::Migration::Script->run_with_options(argv => ["status","--schema_class",'Local::Schema']);
} qr/A \$VERSION needs to be specified in your schema class Local\:\:Schema/;

done_testing;
