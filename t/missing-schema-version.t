use strict;
use warnings;
use Test::Most;
use DBIx::Class::Migration::Script;
use File::Temp 'tempdir';
use lib 't/lib';

use_ok 'Local::Schema';

my $dir = tempdir(DIR => 't', CLEANUP => 1);

lives_ok {
  local @ARGV = (
    "status",
    "--schema_class" => 'Local::Schema',
    "--target_dir" => $dir,
  );
  DBIx::Class::Migration::Script->run_with_options;
};

throws_ok {
  local @ARGV = (
    "status",
    "--schema_class" => 'Local::Schema',
    "--target_dir" => $dir,
    "--database" => 'DefinitelyNotValid',
  );
  DBIx::Class::Migration::Script->run_with_options;
} qr/Unknown database type/;

throws_ok {
  local $Local::Schema::VERSION = undef;
  local @ARGV = (
    "status",
    "--schema_class" => 'Local::Schema',
    "--target_dir" => $dir,
  );
  DBIx::Class::Migration::Script->run_with_options;
} qr/A \$VERSION needs to be specified in your schema class Local\:\:Schema/;

done_testing;
