#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use Test::Most;
use DBIx::Class::Migration::Script;

use File::Spec::Functions 'catfile';
use File::Path 'rmtree';
use Local::Schema;

## Create an in-memory sqlite version of the test schema
(my $schema = Local::Schema->connect('dbi:SQLite::memory:'))
  ->deploy;

## Connect a DBIC migration to that
my $script = DBIx::Class::Migration::Script->new_with_options( schema => $schema );

## Install the version storage and set the version
lives_ok { $script->cmd_prepare() };

done_testing;

END {
  rmtree catfile($script->migration->target_dir, 'migrations');
  rmtree catfile($script->migration->target_dir, 'fixtures');
  unlink catfile($script->migration->target_dir, 'local-schema.db');
}
