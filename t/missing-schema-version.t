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
} 'status = ok';

lives_ok {
  local $ENV{DBIC_MIGRATION_SCHEMA_CLASS} = 'Local::Schema';
  local @ARGV = (
    "status",
    "--target_dir" => $dir,
  );
  DBIx::Class::Migration::Script->run_with_options;
} 'status = ok with ENV';

throws_ok {
  # MooX::Options on ->new failing prints to STDERR, doesn't re-throw
  local @ARGV = (
    "status",
    "--schema_class" => 'Local::Schema',
    "--target_dir" => $dir,
    "--database" => 'DefinitelyNotValid',
  );
  DBIx::Class::Migration::Script->run_with_options;
} qr/Unknown database type/, 'status invalid db = right message';

throws_ok {
  local $Local::Schema::VERSION = undef;
  local @ARGV = (
    "status",
    "--schema_class" => 'Local::Schema',
    "--target_dir" => $dir,
  );
  DBIx::Class::Migration::Script->run_with_options;
} qr/A \$VERSION needs to be specified in your schema class Local\:\:Schema/, 'status no version = not ok';

done_testing;
