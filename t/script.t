use strict;
use warnings;
use lib 't/lib';
use Test::Most;
use DBIx::Class::Migration::Script;
use File::Spec::Functions 'catfile', 'catdir', 'rel2abs';
use Local::Schema;
use File::Temp 'tempdir';
use Cwd 'cwd';
use File::Path 'mkpath';

my $dir = tempdir(DIR => 't', CLEANUP => 1);

## Create an in-memory sqlite version of the test schema
ok my $schema = Local::Schema->connect('dbi:SQLite::memory:');

# SQL_IDENTIFIER_QUOTE_CHAR
$schema->storage->sql_maker->quote_char($schema->storage->dbh->get_info(29));

$schema->deploy;

## Connect a DBIC migration to that
my $script = DBIx::Class::Migration::Script->new_with_options(
  schema => $schema,
  target_dir => $dir,
);

## Install the version storage and set the version
lives_ok { $script->cmd_prepare() };

{
my $previous_cwd = cwd();
my $newdir = tempdir(DIR => 't', CLEANUP => 1);
chdir $newdir;
# to fool File::ShareDir::ProjectDistDir into thinking dev
mkpath catdir(qw(share));
mkpath catdir(qw(t lib Local));
{ open my $fh, '>', catfile(qw(t lib Local Schema.pm)); } # touch
{ open my $fh, '>', catfile(qw(dist.ini)); } # touch
# end fooling File::ShareDir::ProjectDistDir
# make a migration with unspecified target_dir to test default migrations dir
my $script = DBIx::Class::Migration::Script->new_with_options(
  schema_class => 'Local::Schema',
);
is $script->migration->dbic_dh->script_directory,
  rel2abs(catdir(qw(share migrations))),
  'good default migrations dir';
chdir $previous_cwd;
}

done_testing;
