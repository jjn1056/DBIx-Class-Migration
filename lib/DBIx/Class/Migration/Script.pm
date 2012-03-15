package DBIx::Class::Migration::Script;

use Moose;
use MooseX::Attribute::ENV;
use MooseX::Types::LoadableClass 'LoadableClass';
use Pod::Find ();
use Pod::Usage ();

with 'MooseX::Getopt';

sub ENV_PREFIX {
  $ENV{DBIC_MIGRATION_ENV_PREFIX}
    || 'DBIC_MIGRATION';
}

use constant {
  SANDBOX_SQLITE => 'SqliteSandbox',
  SANDBOX_MYSQL => 'MySQLSandbox',
  SANDBOX_POSTGRESQL => 'PostgresqlSandbox',
};

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

has sandbox_class =>  (traits => [ 'Getopt', 'ENV' ], is => 'ro', isa => 'Str',
  predicate=>'has_sandbox_class', default=>SANDBOX_SQLITE,
  cmd_aliases => ['T','sb'], env_prefix=>ENV_PREFIX);

has dbic_fixture_class => (traits => [ 'Getopt' ], is => 'ro', isa => 'Str',
  predicate=>'has_dbic_fixture_class');

has dbic_fixtures_extra_args => (traits => [ 'Getopt' ], is => 'ro', isa => 'HashRef',
  predicate=>'has_dbic_fixtures_extra_args');

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
      dump_all_sets make_schema install_if_needed
      dump diagram install_version_storage);
  }

has migration_class => (
  is => 'ro',
  traits => [ 'NoGetopt'],
  default => 'DBIx::Class::Migration',
  isa => LoadableClass,
  coerce => 1);

has migration => (
  is => 'ro',
  lazy_build => 1,
  handles => { _delegated_commands });

  sub _prepare_schema_args {
    my $self = shift;
    my @schema_args;
    if($self->dsn) {
      push @schema_args, ($self->dsn,
       $self->username, $self->password);
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
  } elsif($self->has_schema_class && $self->schema_class) {
    my @schema_args = $self->_prepare_schema_args;
    $args{schema_class} = $self->schema_class;
    $args{schema_args} = \@schema_args if @schema_args;
  }

  if($self->has_sandbox_class) {
    my ($plus, $class) = ($self->sandbox_class=~/^(\+)*(.+)$/);
    $args{db_sandbox_class} = $plus ? $class : "DBIx::Class::Migration::$class";
  }

  $args{dbic_fixture_class} = $self->dbic_fixture_class
    if $self->has_dbic_fixture_class;

  $args{dbic_fixtures_extra_args} = $self->dbic_fixtures_extra_args
    if $self->has_dbic_fixtures_extra_args;

  return $self->migration_class->new(%args);
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

sub cmd_help {
  my ($self, $subhelp) = @_;
  if($subhelp) {
    die "detailed help not yet available";
  } else {
    Pod::Usage::pod2usage(
      -sections => ['COMMANDS'],
      -verbose => 99,
      -input => Pod::Find::pod_where({-inc => 1}, ref($self)));
  }
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

  if(!$cmd || $cmd eq 'help') {
    $self->cmd_help(@extra_argv);
  } else {
    die "Extra argv detected - command only please\n" if @extra_argv;
    die "No such command ${cmd}\n" unless $self->can("cmd_${cmd}");
    $self->${\"cmd_${cmd}"};
  }
}

sub run_with_options {
  my ($class, %options) = @_;
  $class->new_with_options($class->_defaults, %options)
    ->run;
}

sub run_if_script {
  my $class = shift;
  caller(1) ? $class : $class->run_with_options(@_);
}

__PACKAGE__->meta->make_immutable;
__PACKAGE__->run_if_script;

=head1 NAME

DBIx::Class::Migration::Script - Tools to manage database Migrations

=head1 SYNOPSIS

    dbic-migration status \
      --libs="lib" \
      --schema_class='MyApp::Schema' \
      --dsn='DBI:SQLite:myapp.db'

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

This should be a DSN suitable for L<DBIx::Class::Schema/connect>, something
in the form of C<DBI:SQLite:myapp-schema.db>.

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

=head2 sandbox_class

Accepts String.  Not required.  Defaults to 'SqliteSandbox'

If you don't have a database already running, we will automatically create a
database 'sandbox' in your L</target_dir> that is suitable for development and
rapid prototyping.  This is intended for developers and intended to make life
more simple, particularly for beginners who might not have all the knowledged
needed to setup a database for development purposes.

By default this sandbox is a file based L<DBD::Sqlite> database, which is an
easy option since changes are good this is already installed on your development
computer (and if not it is trivial to install).  

You can change this to either 'PostgresqlSandbox' or 'MySQLSandbox', which will
create a sandbox using either L<DBIx::Class::Migration::MySQLSandbox> or 
L<DBIx::Class::Migration::PostgresqlSandbox> (which in term require the separate
installation of either L<Test::mysqld> or L<Test::postgresql>).  If you are
using one of those open source databases in production, its probably a good
idea to use them in development as well, since there are enough small
differences between them that could make your code break if you used sqlite for
development and postgresql in production.  However this requires a bit more
setup effort, so when you are starting off just sticking to the default sqlite
is probably the easiest thing to do.

You should review the documenation at L<DBIx::Class::Migration::MySQLSandbox> or 
L<DBIx::Class::Migration::PostgresqlSandbox> because those delegates also build
some helper scripts, intended to help you use a sandbox.

Uses L<MooseX::Attribute::ENV> to let you populate values from %ENV.  Uses key
DBIC_MIGRATION_SANDBOX_CLASS

If you need to create your own custom database sandboxes, please see:
L<DBIx::Class::Migration::Sandbox> which is the role your sandbox factory needs
to complete.  You can signify your custom sandbox by using the full package name
with a '+' prepended.  For example:

    sandbox_class => '+MyApp::Schema::CustomSandbox'

You should probably look at the existing sandbox code for thoughts on what a
good sandbox would do.

=head2 migration_class

Accepts String.  Not Required (Defaults: L<DBIx::Class::Migration>)

Should point to the class that does what L<DBIx::Class::Migration> does.  This
is exposed here for those who need to subclass L<DBIx::Class::Migration>.  We
don't expose this attribute to the commandline, so if you are smart enough to
do the subclassing (and sure you need to do that), I will assume you will also
either subclass L<DBIx::Class::Migration:Script> or override then default
value using some standard technique.

=head2 dbic_fixture_class

Accepts: Str, Not Required.

You can use this if you need to make a custom subclass of L<DBIx::Class::Fixtures>.

=head2 dbic_fixtures_extra_args

Accepts: HashRef, Not Required.

If provided will add some additional arguments when creating an instance of
L</dbic_fixture_class>.  You should take a look at the documentation for
L<DBIx::Class::Fixtures> to understand what additional arguments may be of use.

=head1 COMMANDS

    dbic-migration -Ilib install

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

=head2 install_if_needed

Install the database to the current C<$schema> version if it is not currently
installed.  Otherwise this is a nop (even if the database is behind the schema).


=head2 install_version_storage

If the targeted (connected) database does not have the versioning tables
installed, this will install them.  The version is set to whatever your
C<schema> version currently is.

=head2 diagram

Experimental feature.  This command will place a file in your L</target_dir>
called C<db-diagram-vXXX.png> where C<XXX> is he current C<schema> version.

This feature is experimental and currently does not offer any options.

=head2 Command Flags

The following flags are used to modify or inform commands.

=head3 includes

Aliases: I, lib
Value: String or Array of Strings

    dbic-migration --includes lib --includes /opt/perl/lib

Does the same thing as the Perl command line interpreter flag C<I>.  Adds all
the listed paths to C<@INC>.  You will likely use this in order to find your
application schema (subclass of L<DBIx::Class::Schema>.

=head3 schema_class

Value: Str

    dbic-migration prepare --schema_class MyApp::Schema -Ilib

Used to specify the L<DBIx::Class::Schema> subclass which is the core of your
L<DBIx::Class> based ORM managed system.  This is required and the application
cannot function without one.

=head3 target_dir

Aliases: D
Value: Str

    dbic-migration prepare --schema_class MyApp::Schema --target_dir /opt/share

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

    dbic-migration install --username myuser --password mypass --dsn DBI:SQLite:mydb.db

=head3 force_overwrite

Aliases: O
Value: Bool (default: False)

Sometimes you may wish to prepare migrations for the same version more than
once (say if you are developing a new version and need to try out a few options
first).  This lets you deploy over an existing set.  This will of course destroy
and manual modifications you made, buyer beware.)

    dbic-migration prepare --overwrite_migrations

=head3 to_version

Aliases: D
Value: Str (default: Current VERSION of Schema)

    dbic-migration install --to_version 5

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

    dbic-migration prepare --database SQLite --database mysql

Please note if you choose to manually set this value, you won't automatically
get the default, unless you specify as above

=head3 fixture_sets

Alias: fixture_set
Value: Str or Array of Str (default: all set)

When dumping or populating fixture sets, you use this to set which sets.

    dbic-migration dump --fixture_set roles --fixture_set core

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

=head3 sandbox_class

Alias: T
Value: String (default: SqliteSandbox)

If you don't have a target database for your migrations (as you might not for
your development setup, or during initial prototyping) we automatically create
a local database sandbox in your L</target_dir>.  By default this is a
L<DBD::Sqlite> single file database, since this is easy to get installed (you
probably already have it) and is easy to work with.  However, we can also create
database sandboxes for mysql and postgresql (although you will need to get the
L<Test::mysqld> and/or L<Test::postgresql> as well as the correcct DBD installed).

This is handy as you move toward a real production target and know the eventual
database for production.  If you choose to create a postgresql or mysql database
sandbox, they will automatically be created in your L</target_dir>, along with
some helper scripts. See L<DBIx::Class::Migration::PostgresqlSandbox> and
L<DBIx::Class::Migration::MySQLSandbox> for more documentation.

Assuming you've prepared migrations for an alternative sandbox, such as MySQL:

    dbic-migration install --schema_class MyApp::Schema --sandbox_class MySQLSandbox

Would install it.  Like some of the other option flags you can specify with an
%ENV setting:

    export DBIC_MIGRATION_SANDBOX_CLASS=MySQLSandbox

This would be handy if you are always going to target one of the alternative
sandbox types.

The default sqlite sandbox is documented at L<DBIx::Class::Migration::SQLiteSandbox>
although this single file database is pretty straightforward to use.

If you are declaring the value in a subclass, you can use the pre-defined
constants to avoid typos (see L</CONSTANTS>).

=head1 OPTIONAL METHODS FOR SUBCLASSES

If you decide to make a custom subclass of L<DBIx::Class::Migration::Script>,
(you might do this for example to better integrate your migrations with an
existing framework, like L<Catalyst>) you may defined the following option
methods.

=head2 default

Returns a Hash of instantiation values.

Merges some predefined values when instantiating.  For example:

    package MusicBase::Schema::MigrationScript;

    use Moose;
    use MusicBase::Web;

    extends 'DBIx::Class::Migration::Script';

    sub defaults {
      schema => MusicBase::Web->model('Schema')->schema,
    }

    __PACKAGE__->meta->make_immutable;
    __PACKAGE__->run_if_script;

This would create a version of your script that already includes the target
C<schema>.  In this example we will let L<Catalyst> configuration handle which
database to run deployments against.

=head1 ADDITIONAL INFORMATION FOR SUBCLASSERS

The following methods are documented of interest to subclassers.

=head2 run_if_script

Class method that detects if your module is being called as a script.  Place it
at the end of your subclass:

    __PACKAGE__->run_if_script;

This returns true in the case you are using the class as a module, and calls
L</run_with_options> otherwise.  Adding this lets you invoke your class module
as a script from the commandline (saving you the trouble of writing a thin
script wrapper).

    perl -Ilib lib/MyApp/Schema/MigrationScript.pm --status

=head2 run_with_options

Given a Hash of initial arguments, merges those with the results of values passed
on the commandline (via L<MooseX::Getopt>) and run.

=head2 run

Actually runs commands.

=head1 CONSTANTS

The following constants are defined but not exported.  These are used to give
a canonical value for the L</sandbox_class> attribute.

=head2 SANDBOX_SQLITE

SqliteSandbox

=head2 SANDBOX_MYSQL

MySQLSandbox

=head2 SANDBOX_POSTGRESQL

PostgresqlSandbox

=head1 EXAMPLES

Please see L<DBIx::Class::Migration::Tutorial> for more.  Here's some basic use
cases.

=head2 Prepare deployment files for a schema

    dbic-migration prepare --schema_class MyApp::Schema

This will prepare deployment files for just SQLite

    dbic-migration prepare --database SQLite --database MySQL \
      --schema_class MyApp::Schema

This will prepare deployment files for both SQLite and MySQL

=head2 Install database from deployments

    dbic-migration install --schema_class MyApp::Schema

Creates the default sqlite database in the C<share> directory.

    dbic-migration install --schema_class MyApp::Schema --to_version 2

Same as the previous command, but installs version 2, instead of whatever is
the most recent version

    dbic-migration populate --schema_class MyApp::Schema --fixture_set seed

Populates the C<seed> fixture set to the current database (matches the database
version to the seed version.)

=head1 SEE ALSO

L<DBIx::Class::Migration>

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut

