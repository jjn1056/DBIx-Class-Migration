use strict;
use warnings;
use lib 't/lib';
use Test::Most;
use Test::Warnings;
use DBIx::Class::Migration;
use DBIx::Class::Migration::RunScript;
use File::Temp 'tempdir';

my $dir = tempdir(DIR => 't', CLEANUP => 1);

ok(
  my $migration = DBIx::Class::Migration->new(
    schema_class=>'Local::Schema',
    target_dir => $dir,
  ),
  'created migration with schema_class');

$migration->prepare;
$migration->install;

my $runs = sub {
  my $runscript = shift;
  ok $runscript->can('dbh'), 'Got dbh';
  ok $runscript->can('schema'), 'Got schema';
  ok $runscript->schema->resultset('Artist'), 'got Artist RS';
};

subtest SUGAR2 => sub {
  my $code = migrate {
    $runs->(shift)
  };
  $code->($migration->schema, [1,2]);
};


done_testing;
