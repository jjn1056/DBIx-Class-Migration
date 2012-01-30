package DBIx::Class::Migration::Script;

use Moose;
use MooseX::Attribute::ENV;
use DBIx::Class::Migration;
use Moose::Util::TypeConstraints qw(enum);

with 'MooseX::Getopt';

sub ENV_PREFIX {
  $ENV{DBIC_MIGRATION_ENV_PREFIX}
    || 'DBIC_MIGRATION';
}

sub SANDBOX_TYPES { qw(sqlite mysql postgresql) }

has includes => (
  traits => ['Getopt'],
  is => 'ro',
  isa => 'ArrayRef',
  predicate => 'has_includes',
  cmd_aliases => ['I', 'libs']);

has schema => (is=>'ro', predicate=>'has_schema');

has schema_class => (traits => [ 'Getopt', 'ENV' ], is => 'ro', isa => 'Str',
  predicate=>'has_schema_class', env_prefix=>ENV_PREFIX, cmd_aliases => 'S');

has target_dir => (traits => [ 'Getopt' ], is => 'ro', isa=> 'Str',
  predicate=>'has_target_dir', cmd_aliases => 'dir');

has username => (traits => [ 'Getopt', 'ENV' ], is => 'ro', isa => 'Str',
  default => '', env_prefix=>ENV_PREFIX, cmd_aliases => 'U');

has password => (traits => [ 'Getopt', 'ENV' ], is => 'ro', isa => 'Str',
  default => '', env_prefix=>ENV_PREFIX, cmd_aliases => 'P');

has dsn => (traits => [ 'Getopt', 'ENV' ], is => 'ro',
  env_prefix=>ENV_PREFIX, isa => 'Str');

has force_overwrite => (traits => [ 'Getopt' ], is => 'ro', isa => 'Bool',
  predicate=>'has_force_overwrite', cmd_aliases => 'O');

has to_version => (traits => [ 'Getopt' ], is => 'ro', isa => 'Int',
  predicate=>'has_to_version', cmd_aliases => 'V');

has databases => (traits => [ 'Getopt' ], is => 'ro', isa => 'ArrayRef',
  predicate=>'has_databases', cmd_aliases => 'database');

has sandbox_type =>  (traits => [ 'Getopt' ], is => 'ro',
  predicate=>'has_sandbox_type', isa=>enum( +[SANDBOX_TYPES] ),
  default=>'sqlite');


has fixture_sets => (
  traits => [ 'Getopt' ],
  is=>'ro',
  isa=>'ArrayRef',
  default => sub { +['all_tables'] },
  cmd_aliases => 'fixture_set');

  sub _delegated_commands {
    map { 'cmd_'.$_ => $_ } qw(
      version status prepare install upgrade
      downgrade drop_tables delete_table_rows
      dump_all_sets make_schema);
  }

has migration => (
  is => 'ro',
  lazy_build => 1,
  handles => { _delegated_commands });

  sub _prepare_schema_args {
    my $self = shift;
    my @schema_args;
    if($self->dsn) {
      push @schema_args, $self->dsn;
      push @schema_args, $self->username;
      push @schema_args, $self->password;
    }
    return @schema_args;
  }

  sub _prepare_dbic_dh_args {
    my $self = shift;
    return (
      ($self->has_force_overwrite ? (force_overwrite => $self->force_overwrite) : ()),
      ($self->has_target_dir ? (script_directory=>$self->target_dir) : ()),
      ($self->has_to_version ? (to_version=>$self->to_version) : ()),
      ($self->has_databases ? (databases=>$self->databases) : ()),
    );
  }

sub _build_migration {
  my $self = shift;
  my %dbic_dh_args = $self->_prepare_dbic_dh_args;
  my %args = (%dbic_dh_args ? (dbic_dh_args => \%dbic_dh_args) : ());

  if($self->has_schema) {
    $args{schema} = $self->schema;
  } else {
    my @schema_args = $self->_prepare_schema_args;
    $args{schema_class} = $self->schema_class;
    $args{schema_args} = \@schema_args if @schema_args;
  }

  if($self->has_sandbox_type) {
    my $base = 'DBIx::Class::Migration::';
    for my $type ($self->sandbox_type) {
      $args{db_sandbox_class} = $base . 'SqliteSandbox' if $type eq 'sqlite';
      $args{db_sandbox_class} = $base . 'MySQLSandbox' if $type eq 'mysql';
      $args{db_sandbox_class} = $base . 'PostgresqlSandbox' if $type eq 'postgresql';
    }
  }

  return DBIx::Class::Migration->new(%args);
}

sub cmd_dump_named_sets {
  my $self = shift;
  $self->migration
    ->dump_named_sets(@{$self->fixture_sets});
}

sub cmd_populate {
  my $self = shift;
  $self->migration
    ->populate(@{$self->fixture_sets});
}

sub _import_libs {
  my ($self, @libs) = @_;
  require lib;
  lib->import(@libs);
}

sub _defaults {
  my $class = shift;
  $class->can('defaults') ? $class->defaults : ();
}

sub run {
  my ($self) = @_;
  my ($cmd, @extra_argv) = @{$self->extra_argv};

  $self->_import_libs(@{$self->includes})
    if $self->has_includes;

  die "Must supply a command\n" unless $cmd;
  die "Extra argv detected - command only please\n" if @extra_argv;
  die "No such command ${cmd}\n" unless $self->can("cmd_${cmd}");

  $self->${\"cmd_${cmd}"};
}

sub run_if_script {
  my $class = shift;
  caller(1) ? 1 : $class->new_with_options($class->_defaults)->run;
}

__PACKAGE__->meta->make_immutable;
__PACKAGE__->run_if_script;

=head1 NAME

DBIx::Class::Migration::Script - Tools to manage database Migrations

=head1 SYNOPSIS

    dbic-migration status \
      --libs="lib" \
      --schema_class='MyApp::Schema' \
      --dns='DBI:SQLite:myapp.db'

=head1 DESCRIPTION

This is a class which provides an interface mapping between the commandline
script L<dbic-migration> and the back end code that does the heavy lifting,
L<DBIx::Class::Migration>.  This class has very little of it's own
functionality, since it basically acts as processing glue between that
commandline application and the code which does all the work.

You should look at L<DBIx::Class::Migration> and the tutorial over at
L<DBIx::Class::Migration::Tutorial> to get started.  This is basically
API level docs and a command summary which is likely to be useful as a
reference when you are familiar with the system.

=head1 ATTRIBUTES

This class defines the following attributes.

=head2 migration

This contains an instance of L<DBIx::Class::Migration> which is constructed
from various attributes described futher in these docs.

This is basically a delegate for all the commands you perform with this
interface.

=head2 includes

Accepts ArrayRef. Not required.

Similar to the commandline switch C<I> for the C<perl> interpreter.  It adds
to C<@INC> for when we want to search for modules to load.  This is primarily
useful for specifying a path to find a L</schema_class>.

We make no attempt to check the validity of any paths specified.  Buyer beware.

=head2 schema_class

Accepts Str.  Required.

This is the schema we use as the basic for creating, managing and running your
deployments.  This should be the full package namespace defining your subclass
of L<DBIx::Class::Schema>.  For example C<MyApp::Schema>.

Uses L<MooseX::Attribute::ENV> to let you populate values from %ENV.  Uses key
DBIC_MIGRATION_SCHEMA_CLASS

If the L</schema_class> cannot be loaded, a hard exception will be thrown.

=head2 target_dir

Accepts Str.  Required.

This is the directory we store our migration and fixture files.  Inside this
directory we will create a C<fixtures> and C<migrations> sub-directory.

Although you can specify the directory, if you leave it undefined, we will use
L<File::ShareDir::ProjectDistDir> to locate the C<share> directory for your
project and place the files there.  This is the recommended approach, and is
considered a community practice in regards to where to store your distribution
non code files.  Please see L<File::ShareDir::ProjectDistDir> as well as
L<File::ShareDir> for more information.

Uses L<MooseX::Attribute::ENV> to let you populate values from %ENV.  Uses key
DBIC_MIGRATION_TARGET_DIR

=head2 username

Accepts Str.  Not Required

This should be the username for the database we connect to for deploying
ddl, ddl changes and fixtures.

Uses L<MooseX::Attribute::ENV> to let you populate values from %ENV.  Uses key
DBIC_MIGRATION_USERNAME

=head2 password

Accepts Str.  Not Required

This should be the password for the database we connect to for deploying
ddl, ddl changes and fixtures.

Uses L<MooseX::Attribute::ENV> to let you populate values from %ENV.  Uses key
DBIC_MIGRATION_PASSWORD

=head2 dsn

Accepts Str.  Not Required

This is the DSN for the database you are going to be targeting for deploying
or altering ddl, and installing or generating fixtures.

This should be a DSN suitable for L<DBIx::Class::Schema/connect), something
in the form of C<DBI:SQLite:myapp-schema.db)>.

Please take care where you point this (like production :) )

If you don't provide a value, we will automatically create a SQLite based
database connection with the following DSN:

    DBD:SQLite:[path to target_dir]/[db_file_name].db

Where c<[path to target_dir]> is L</target_dir> and [db_file_name] is a converted
version of L</schema_class>.  For example if you set L<schema_class> to:

    MyApp::Schema

Then [db_file_name] would be C<myapp-schema>.

Please remember that you can generate deployment files for database types
other than the one you've defined in L</dsn>, however since different databases
enforce constraints differently it would not be impossible to generate fixtures
that can be loaded by one database but not another.  Therefore I recommend
always generated fixtures from a database that is consistent across enviroments.

Uses L<MooseX::Attribute::ENV> to let you populate values from %ENV.  Uses key
DBIC_MIGRATION_DSN

=head2 force_overwrite

Accepts Bool.  Not Required.  Defaults to False.

Used when building L</migration> to en / disable  the L<DBIx::Class::DeploymentHandler>
option C<force_overwrite>.  This is used when generating DDL and related
files for a given version of your L</_schema> to decide if it is ok to overwrite
deployment files.  You might need this if you deploy a version of the database
during development and then need to make more changes or fixes for that version.

=head2 to_version

Accepts Int.  Not Required.

Used to establish a target version when running an install.  You can use this
to force install a version of the database other then your current L</_schema>
version.  You might want this when you need to force install a lower version as
part of your development process for changing the database.

If you leave this undefined, no default value is built, however
L<DBIx::Class::DeploymentHandler> will assume you want whatever is the value of
your $schema->version.

=head2 databases

Accepts ArrayRef.  Not Required.

Used when building L</migration> to define the target databases we are building
migration files for.  You can name any of the databases currently supported by
L<SQLT>.  If you leave this undefined we will derive a value based on the value
of L</dsn>.  For example, if your L</dsn> is "DBI:SQLite:test.db", we will set
the valuye of L</databases> to C<['SQLite']>.

=head2 fixture_sets

Accepts ArrayRef.  Not Required. Defaults to ['all_tables'].

This defines a list of fixture sets that we use for dumping or populating
fixtures.  Defaults to the C<['all_tables']> set, which is the one set we build
automatically for each version of the database we prepare deployments for.

=head2 sandbox_type

Accepts Enum (sqlite, mysql or postgresql).  Required, defaults to 'sqlite'.

If you don't have a database already running, we will automatically create a
database 'sandbox' in your L</target_dir> that is suitable for development and
rapid prototyping.  This is intended for developers and intended to make life
more simple, particularly for beginners who might not have all the knowledged
needed to setup a database for development purposes.

By default this sandbox is a file based L<DBD::Sqlite> database, which is an
easy option since changes are good this is already installed on your development
computer (and if not it is trivial to install).  

You can change this to either 'postgresql' or 'mysql', which will create a 
sandbox using either L<DBIx::Class::Migration::MySQLSandbox> or 
L<DBIx::Class::Migration::PostgresqlSandbox> (which in term require the separate
installation of either L<Test::mysqld> or L<Test::postgresql>).  If you are
using one of those open source databases in production, its probably a good
idea to use them in development as well, since there are enough small
differences between them that could make your code break if you used sqlite for
development and postgresql in production.  However this requires a bit more
setup effort, so when you are starting off just sticking to the default sqlite
is probably the easiest thing to do.

YOu should review the documenation at L<DBIx::Class::Migration::MySQLSandbox> or 
L<DBIx::Class::Migration::PostgresqlSandbox> because those delegates also build
some helper scripts, intended to help you use a sandbox.

=head1 COMMANDS

    dbic_migration -Ilib install

Since this class consumes the L<MooseX::GetOpt> role, it can be run directly
as a commandline application.  The following is a list of commands we support
as well as the options / flags associated with each command.

=head2 help

Summary of commands and aliases.

=head2 version

prints the current version of the application to STDOUT

=head2 status

Returns the state of the deployed database (if it is deployed) and the state
of the current C<schema>

=head2 prepare

Creates a C<fixtures> and C<migrations> directory under L</target_dir> (if they
don't already exist) and makes deployment files for the current schema.  If
deployment files exist, will fail unless you L</overwrite_migrations> and
L</overwrite_fixtures>.

=head2 install

Installs either the current schema version (if already prepared) or the target
version specified via L</to_version> to the database connected via the L</dsn>,
L</username> and L</password>

=head2 upgrade

Run upgrade files to either bring the database into sync with the current
schema version, or stop at an intermediate version specified via L</to_version>

=head2 downgrade

Run down files to bring the database down to the version specified via
L</to_version>

=head2 dump_named_sets

Given listed L<fixture_sets>, dump files for the current database version (not
the current schema version)

=head2 dump_all_sets

Just dump all the sets for the current database

=head2 populate

Given listed L<fixture_sets>, populate a database with fixtures for the matching
version (matches database version to fixtures, not the schema version)

=head2 drop_tables

Drops all the tables in the connected database with no backup or recovery.  For
real! (Make sure you are not connected to Prod, for example)

=head2 delete_table_rows

does a C<delete> on each table in the database, which clears out all your data
but preserves tables.  For Real!  You might want this if you need to load
and unload fixture sets during testing, or perhaps to get rid of data that
accumulated in the database while running an app in development, before dumping
fixtures.

Skips the table C<dbix_class_deploymenthandler_versions>, so you don't lose
deployment info (this is different from L</drop_tables> which does delete it.)

=head2 make_schema

Creates DBIC schema files from the currently deployed database into your target
directory.  You can use this to bootstrap your ORM, or if you get confused about
what the deployment perl run files get for schema.

=head2 Command Flags

The following flags are used to modify or inform commands.

=head3 includes

Aliases: I, lib
Value: String or Array of Strings

    dbic_migration --includes lib --includes /opt/perl/lib

Does the same thing as the Perl command line interpreter flag C<I>.  Adds all
the listed paths to C<@INC>.  You will likely use this in order to find your
application schema (subclass of L<DBIx::Class::Schema>.

=head3 schema_class

Value: Str

    dbic_migration prepare --schema_class MyApp::Schema -Ilib

Used to specify the L<DBIx::Class::Schema> subclass which is the core of your
L<DBIx::Class> based ORM managed system.  This is required and the application
cannot function without one.

=head3 target_dir

Aliases: D
Value: Str

    dbic_migration prepare --schema_class MyApp::Schema --target_dir /opt/share

We need a directory path that is used to store your fixtures and migration
files.  By default this will be the C<share> directory for the application
where your L</schema_class> resides.  I recommend you leave it alone since
this is a reasonable Perl convention for non code data, and there's a decent
ecosystem of tools around it, however if you need to place the files in an
alternative location (for example you have huge fixture sets and you don't
want them in you core repository, or you can't store them in a limited space
filesystem) this will let you do it.  Option and defaults as discussed.

=head3 username

Aliases: U
Value:  Str

=head3 password

Aliases: P
Value: String

=head3 dsn

Value: String

These three commandline flags describe how to connect to a target, physical
database, where we will deploy migrations and fixtures.  If you don't provide
them, we will automatically deploy to a L<DBD::SQLite> managed database located
at L</target_dir>.

    dbic_migration install --username myuser --password mypass --dsn DBI:SQLite:mydb.db

=head3 force_overwrite

Aliases: O
Value: Bool (default: False)

Sometimes you may wish to prepare migrations for the same version more than
once (say if you are developing a new version and need to try out a few options
first).  This lets you deploy over an existing set.  This will of course destroy
and manual modifications you made, buyer beware.)

    dbic_migration prepare --overwrite_migrations

=head3 to_version

Aliases: D
Value: Str (default: Current VERSION of Schema)

    dbic_migration install --to_version 5

Used to specify which version we are going to deploy.  Defaults to whatever
is the most current version you've prepared.

Use this when you need to force install an older version, such as when you are
roundtripping prepares while fiddling with a new database version.

=head3 databases

Alias: database
Value: Str or Array of Str (default: SQLite)

You can prepare deployment for any database type that L<SQLT> understand.  By
default we only prepare a deployment version for the database which matches
the L<dsn> you specified but you can use this to prepare additional deployments

    dbic_migration prepare --database SQLite --database mysql

Please note if you choose to manually set this value, you won't automatically
get the default, unless you specify as above

=head3 fixture_sets

Alias: fixture_set
Value: Str or Array of Str (default: all set)

When dumping or populating fixture sets, you use this to set which sets.

    dbic_migration dump --fixture_set roles --fixture_set core

Please note that if you manually describe your sets as in the above example,
you don't automatically get the C<all_tables> set, which is a fixture set of all
database information and not 'all' the sets.

We automatically create the C<all_tables> fixture set description file for you when
you prepare a new migration of the schema.  You can use this set for early
testing but I recommend you study L<DBIx::Class::Fixtures> and learn the set
configuration rules, and create limited fixture sets for given purposes, rather
than just dump / populate everything, since that is like to get big pretty fast

My recommendation is to create a core 'seed' set, of default database values,
such as role types, default users, lists of countries, etc. and then create a
'demo' or 'dev' set that contains extra information useful to populate a
database so that you can run test cases and develop against.

=head1 EXAMPLES

Please see L<DBIx::Class::Migration::Tutorial> for more.  Here's some basic use
cases.

head2 Prepare deployment files for a schema

    dbic_migration prepare --schema_class MyApp::Schema

This will prepare deployment files for just SQLite

    dbic_migration prepare --database SQLite --database mysql \
      --schema_class MyApp::Schema

This will prepare deployment files for both SQLite and MySQL

head2 Install database from deployments

    dbic_migration install --schema_class MyApp::Schema

Creates the default sqlite database in the C<share> directory.

    dbic_migration install --schema_class MyApp::Schema --to_version 2

Same as the previous command, but installs version 2, instead of whatever is
the most recent version

    dbic_migration populate --schema_class MyApp::Schema --fixture_set seed

Populates the C<seed> fixture set to the current database (matches the database
version to the seed version.

=head1 SEE ALSO

L<DBIx::Class::Migration>

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut

