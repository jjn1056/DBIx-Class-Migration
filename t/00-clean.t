#!/usr/bin/env perl

## Just a test class to make sure we have a nice, clean target_dir
## in case a previous test run make a mess.

use lib 't/lib';
use Test::Most;
use DBIx::Class::Migration::Population;
use File::Spec::Functions 'catfile';
use File::Path 'rmtree';

ok(  my $p = DBIx::Class::Migration::Population->new(schema_class=>'Local::Schema'),
     'created population object from schema_class');

rmtree catfile($p->target_dir, 'migrations');
rmtree catfile($p->target_dir, 'fixtures');
unlink catfile($p->target_dir, 'local-schema.db');
rmtree catfile($p->target_dir, 'local-schema');

done_testing;
