#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use Test::Most;
use DBIx::Class::Migration::Script;
use Local::Schema;
use File::Temp 'tempdir';

my $dir = tempdir(DIR => 't', CLEANUP => 1);

## Create an in-memory sqlite version of the test schema
(my $schema = Local::Schema->connect('dbi:SQLite::memory:'))
  ->deploy;

## Connect a DBIC migration to that
my $script = DBIx::Class::Migration::Script->new_with_options(
  schema => $schema,
  target_dir => $dir,
);

## Install the version storage and set the version
lives_ok { $script->cmd_prepare() };

done_testing;
