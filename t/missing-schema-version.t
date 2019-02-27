use strict;
use warnings;
use Test::Most;
use DBIx::Class::Migration::Script;
use File::Temp 'tempdir';
use lib 't/lib';

use_ok 'Local::Schema';

my $dir = tempdir(DIR => 't', CLEANUP => 1);

lives_ok {
  DBIx::Class::Migration::Script->run_with_options(argv => [
    "status",
    "--schema_class" => 'Local::Schema',
    "--target_dir" => $dir,
  ]);
}; 

throws_ok {
  DBIx::Class::Migration::Script->run_with_options(argv => [
    "status",
    "--schema_class" => 'Local::Schema',
    "--target_dir" => $dir,
    "--database" => 'DefinitelyNotValid',
  ]);
} qr/Unknown database type/;

local $Local::Schema::VERSION = undef;

throws_ok {
  DBIx::Class::Migration::Script->run_with_options(argv => [
    "status",
    "--schema_class" => 'Local::Schema',
    "--target_dir" => $dir,
  ]);
} qr/A \$VERSION needs to be specified in your schema class Local\:\:Schema/;

done_testing;
