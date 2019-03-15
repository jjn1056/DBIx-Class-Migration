package DBIx::Class::Migration::Script;

use Moo;
use MooX::Attribute::ENV;
use Pod::Find ();
use Pod::Usage ();
use DBIx::Class::Migration::Types -all;
use Log::Any;
use Carp 'croak';

use MooX::Options protect_argv => 0;

sub _log_die {
  my ($self, $msg) = @_;
  $self->log->error($msg);
  croak $msg;
}

sub ENV_PREFIX {
  $ENV{DBIC_MIGRATION_ENV_PREFIX}
    || 'DBIC_MIGRATION';
}

use constant {
  SANDBOX_SQLITE => 'SqliteSandbox',
  SANDBOX_MYSQL => 'MySQLSandbox',
  SANDBOX_POSTGRESQL => 'PostgresqlSandbox',
};

has log => (
  is  => 'ro',
  isa => InstanceOf['Log::Any::Proxy'],
  default => sub { Log::Any->get_logger( category => 'DBIx::Class::Migration') },
);

option includes => (
  is => 'ro',
  isa => ArrayRef,
  predicate => 'has_includes',
  short => join('|', qw(include I lib libs)),
  format => 's@',
);

has schema => (
  is=>'ro', predicate=>'has_schema',
);

option schema_class => (
  is => 'ro', isa => Str,
  predicate=>'has_schema_class', env_prefix=>ENV_PREFIX,
  short => 'S', format => 's',
);

option target_dir => (
  is => 'ro', isa=> Str,
  predicate=>'has_target_dir', env_prefix=>ENV_PREFIX,
  short => 'dir', format => 's',
);

option sandbox_dir => (
  is => 'ro', isa=> Str,
  predicate=>'has_sandbox_dir', env_prefix=>ENV_PREFIX,
  format => 's',
);

option username => (
  is => 'ro', isa => Str,
  default => '', env_prefix=>ENV_PREFIX, short => 'U',
  format => 's',
);

option password => (
  is => 'ro', isa => Str,
  default => '', env_prefix=>ENV_PREFIX, short => 'P',
  format => 's',
);

option dsn => (
  is => 'ro',
  env_prefix=>ENV_PREFIX, isa => Str,
  format => 's',
);

option force_overwrite => (
  is => 'ro', isa => Bool,
  predicate=>'has_force_overwrite',
  short => 'O',
);

option to_version => (
  is => 'ro', isa => Int,
  predicate=>'has_to_version',
  short => 'V', format => 'i',
);

option sql_translator_args => (
  is => 'ro', isa => HashRef,
  predicate=>'has_sql_translator_args',
  default => sub { +{ quote_identifiers => 1 }},
  format => 's%',
);

option databases => (
  is => 'ro', isa => ArraySQLTProducers,
  predicate=>'has_databases',
  short => 'database', format => 's@',
);

option sandbox_class => (
  is => 'ro', isa => Str,
  predicate=>'has_sandbox_class', default=>SANDBOX_SQLITE,
  env_prefix=>ENV_PREFIX,
  short => 'T|sb', format => 's',
);

option dbic_fixture_class => (
  is => 'ro', isa => Str,
  predicate=>'has_dbic_fixture_class',
  format => 's',
);

option dbic_fixtures_extra_args => (
  is => 'ro', isa => HashRef,
  predicate=>'has_dbic_fixtures_extra_args',
  format => 's%',
);

option dbic_connect_attrs => (
  is => 'ro', isa => HashRef,
  predicate=>'has_dbic_connect_attrs',
  format => 's%',
);

option dbi_connect_attrs => (
  is => 'ro', isa => HashRef,
  predicate=>'has_dbi_connect_attrs',
  format => 's%',
);

option extra_schemaloader_args => (
  is => 'ro', isa => HashRef,
  predicate=>'has_extra_schemaloader_args',
  format => 's%',
);

option fixture_sets => (
  is=>'ro',
  isa=>ArrayRef,
  default => sub { +['all_tables'] },
  short => 'fixture_set', format => 's@',
);

  sub _delegated_commands {
    map { 'cmd_'.$_ => $_ } qw(
      version status prepare install upgrade
      downgrade drop_tables delete_table_rows
      dump_all_sets make_schema install_if_needed
      dump diagram install_version_storage );
  }

has migration_class => (
  is => 'ro',
  default => 'DBIx::Class::Migration',
  isa => LoadableClass,
);

option migration_sandbox_builder_class => (
  is => 'ro', isa => Str, predicate=>'has_migration_sandbox_builder_class',
  format => 's%',
);

has migration => (
  is => 'lazy',
  handles => { _delegated_commands },
);

  sub _prepare_schema_args {
    my $self = shift;
    my @schema_args;
    if($self->dsn) {
      push @schema_args, ($self->dsn,
       $self->username, $self->password);
    } else {
      warn "no --dsn argument was found, defaulting to a local SQLite database\n";
    }
    if($self->has_dbi_connect_attrs) {
      push @schema_args, $self->dbi_connect_attrs;
    }
    if($self->has_dbic_connect_attrs) {
      push @schema_args, {} unless $self->has_dbi_connect_attrs;
      push @schema_args, $self->dbic_connect_attrs;
    }
    return @schema_args;
  }

  sub _prepare_dbic_dh_args {
    my $self = shift;
    return (
      ($self->has_force_overwrite ? (force_overwrite => $self->force_overwrite) : ()),
      ($self->has_target_dir && $self->target_dir ? (script_directory=>$self->target_dir) : ()),
      ($self->has_to_version ? (to_version=>$self->to_version) : ()),
      ($self->has_databases ? (databases=>$self->databases) : ()),
      ($self->has_sql_translator_args ? (sql_translator_args=>$self->sql_translator_args) : ()),
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

  $args{target_dir} = $self->target_dir
    if $self->has_target_dir && $self->target_dir;

  if($self->has_sandbox_class) {
    my ($plus, $class) = ($self->sandbox_class=~/^(\+)*(.+)$/);
    $args{db_sandbox_class} = $plus ? $class : "DBIx::Class::Migration::$class";
  }

  $args{dbic_fixture_class} = $self->dbic_fixture_class
    if $self->has_dbic_fixture_class;

  $args{dbic_fixtures_extra_args} = $self->dbic_fixtures_extra_args
    if $self->has_dbic_fixtures_extra_args;

  $args{extra_schemaloader_args} = $self->extra_schemaloader_args
    if $self->has_extra_schemaloader_args;

  if($self->has_migration_sandbox_builder_class) {
    my ($plus, $class) = ($self->migration_sandbox_builder_class=~/^(\+)*(.+)$/);
    $args{db_sandbox_builder_class} = $plus ? $class : "DBIx::Class::Migration::$class";
  }

  # Because this attribute uses the ENV thing, its always going to meet the 'has'
  # Requirement, but it will be '' so we can also check for truthiness.
  $args{db_sandbox_dir} = $self->sandbox_dir
    if $self->has_sandbox_dir && $self->sandbox_dir;
  
  return $self->migration_class->new(%args);
}

sub cmd_dump_named_sets {
  my $self = shift;
  $self->migration
    ->dump_named_sets(@{$self->fixture_sets});
}

sub cmd_delete_named_sets {
  my $self = shift;
  $self->migration
    ->delete_named_sets(@{$self->fixture_sets});
}

sub cmd_populate {
  my $self = shift;
  $self->migration
    ->populate(@{$self->fixture_sets});
}

sub cmd_help {
  my ($self, $subhelp) = @_;
  my $docs = "DBIx::Class::Migration::Script::Help" . ($subhelp ? "::$subhelp" : "");
  Pod::Usage::pod2usage(
    -verbose => 2,
    -exitval => 'NOEXIT',
    -input => Pod::Find::pod_where({-inc => 1}, $docs));
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
  my ($argv, @extra_argv) = @ARGV;

  $self->_import_libs(@{$self->includes})
    if $self->has_includes;

  if(!$argv || $argv eq 'help') {
    $self->cmd_help(@extra_argv);
  } else {
    foreach my $cmd ($argv, @extra_argv) {
      $self->can("cmd_${cmd}") ?
        $self->${\"cmd_${cmd}"} :
        $self->_log_die( "No such command ${cmd}\n" );
    }

  }
}

sub run_with_options {
  my ($class, %options) = @_;
  $class->new_with_options($class->_defaults, %options)
    ->run;
}

sub new_with_defaults {
  my $class = shift;
  return $class->new_with_options($class->_defaults, @_);
}

{
# overrides MooX::Options::Role's one to not exit() on ->new exception
no warnings 'redefine';
sub new_with_options {
  my ($class, %params) = @_;
  my %cmdline_params = $class->parse_options(%params);
  if ($cmdline_params{h}) {
    return $class->options_usage($params{h}, $cmdline_params{h});
  }
  if ($cmdline_params{help} ) {
    return $class->options_help($params{help}, $cmdline_params{help});
  }
  if ($cmdline_params{man}) {
    return $class->options_man($cmdline_params{man});
  }
  if ($cmdline_params{usage} ) {
    return $class->options_short_usage($params{usage}, $cmdline_params{usage});
  }
  $class->new(%cmdline_params);
}
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
      --lib="lib" \
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

Uses L<MooX::Attribute::ENV> to let you populate values from %ENV.  Uses key
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

Uses L<MooX::Attribute::ENV> to let you populate values from %ENV.  Uses key
DBIC_MIGRATION_TARGET_DIR

=head2 sandbox_dir

Accepts Str.  Optional

Used if you wish to build the sandbox (if you are building one) in a location that
is not the 'target_dir'.  For example you might do this to make it easier to not
accidentally check the sandbox into the repository or if you are reusing it across
several projects.

=head2 username

Accepts Str.  Not Required

This should be the username for the database we connect to for deploying
ddl, ddl changes and fixtures.

Uses L<MooX::Attribute::ENV> to let you populate values from %ENV.  Uses key
DBIC_MIGRATION_USERNAME

=head2 password

Accepts Str.  Not Required

This should be the password for the database we connect to for deploying
ddl, ddl changes and fixtures.

Uses L<MooX::Attribute::ENV> to let you populate values from %ENV.  Uses key
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

Uses L<MooX::Attribute::ENV> to let you populate values from %ENV.  Uses key
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
L<SQL::Translator>.  If you leave this undefined we will derive a value based on the value
of L</dsn>.  For example, if your L</dsn> is "DBI:SQLite:test.db", we will set
the value of L</databases> to C<['SQLite']>.

=head2 sql_translator_args

Accepts HashRef.  Not Required.

Used when building L</migration> to set the L<DBIx::Class::DeploymentHandler>
option C<sql_translator_args>. This can be used to specify options for
L<SQL::Translator>, for example:

    producer_args => { postgres_version => '9.1' }

to define the database version for SQL producer. Defaults to setting
C<quote_identifiers> to a true value, which despite being documented as
the default, is not the case in practice.

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
installation of either L<Test::mysqld> or L<Test::Postgresql58>).  If you are
using one of those open source databases in production, its probably a good
idea to use them in development as well, since there are enough small
differences between them that could make your code break if you used sqlite for
development and postgresql in production.  However this requires a bit more
setup effort, so when you are starting off just sticking to the default sqlite
is probably the easiest thing to do.

You should review the documenation at L<DBIx::Class::Migration::MySQLSandbox> or 
L<DBIx::Class::Migration::PostgresqlSandbox> because those delegates also build
some helper scripts, intended to help you use a sandbox.

Uses L<MooX::Attribute::ENV> to let you populate values from %ENV.  Uses key
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

=head2 dbi_connect_attrs

Accepts: HashRef, Not Required.

If you are specifying a DSN, you might need to provide some additional args
to L<DBI> (see L<DBIx::Class::Storage::DBI/connect_info> for more).

=head2 dbic_connect_attrs

Accepts: HashRef, Not Required.

If you are specifying a DSN, you might need to provide some additional args
to L<DBIx::Class> (see L<DBIx::Class::Storage::DBI/connect_info> for more).

You can also see L<DBIx::Class::Storage::DBI/DBIx::Class-specific-connection-attributes>
for more information on what this can do for you.  Chances are good if you
need this you will also want to subclass L<DBIx::Class::Migration::Script> as
well.

Common uses for this is to run SQL on startup and set Postgresql search paths.

=head2 extra_schemaloader_args

Accepts: HashRef, Not Required.

Used to populate L<DBIx::Class::Migration/extra_schemaloader_args>

=head2 migration_sandbox_builder_class

Accepts: String (Classname), Not Required.

Used to set L<DBIx::Class::Migration/db_sandbox_builder_class>.  You probably
won't mess with this unless you are writing your own Sandbox builder class, or
using the alternative builder L<DBIx::Class::Migration::TempDirSandboxBuilder>
for creating temporary sandboxes when you want to test your migrations.

=head1 COMMANDS

    dbic-migration -Ilib install

Since this class uses L<MooX::Options>, it can be run directly
as a commandline application.  The following is a list of commands we support
as well as the options / flags associated with each command.

=head2 help

See L<DBIx::Class::Migration::Script::Help::help>.

=head2 version

See L<DBIx::Class::Migration::Script::Help::version>.

=head2 status

See L<DBIx::Class::Migration::Script::Help::status>.

=head2 prepare

See L<DBIx::Class::Migration::Script::Help::prepare>.

=head2 install

See L<DBIx::Class::Migration::Script::Help::install>.

=head2 upgrade

See L<DBIx::Class::Migration::Script::Help::upgrade>.

=head2 downgrade

See L<DBIx::Class::Migration::Script::Help::downgrade>.

=head2 dump_named_sets

See L<DBIx::Class::Migration::Script::Help::dump_named_sets>.

=head2 dump_all_sets

See L<DBIx::Class::Migration::Script::Help::dump_all_sets>.

=head2 populate

See L<DBIx::Class::Migration::Script::Help::populate>.

=head2 drop_tables

See L<DBIx::Class::Migration::Script::Help::drop_tables>.

=head2 delete_table_rows

See L<DBIx::Class::Migration::Script::Help::delete_table_rows>.

=head2 make_schema

See L<DBIx::Class::Migration::Script::Help::make_schema>.

=head2 install_if_needed

See L<DBIx::Class::Migration::Script::Help::install_if_needed>.

=head2 install_version_storage

See L<DBIx::Class::Migration::Script::Help::install_version_storage>.

=head2 diagram

See L<DBIx::Class::Migration::Script::Help::diagram>.

=head2 delete_named_sets

See L<DBIx::Class::Migration::Script::Help::delete_named_sets>.

=head2 Command Flags

The following flags are used to modify or inform commands.

=head3 includes

See L<DBIx::Class::Migration::Script::Help::includes>.

=head3 schema_class

See L<DBIx::Class::Migration::Script::Help::schema_class>.

=head3 target_dir

See L<DBIx::Class::Migration::Script::Help::target_dir>.

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

See L<DBIx::Class::Migration::Script::Help::force_overwrite>

=head3 to_version

See L<DBIx::Class::Migration::Script::Help::to_version>

=head3 databases

See L<DBIx::Class::Migration::Script::Help::databases>

=head3 fixture_sets

See L<DBIx::Class::Migration::Script::Help::fixture_sets>

=head3 sandbox_class

See L<DBIx::Class::Migration::Script::Help::sandbox_class>

The default sqlite sandbox is documented at L<DBIx::Class::Migration::SQLiteSandbox>
although this single file database is pretty straightforward to use.

If you are declaring the value in a subclass, you can use the pre-defined
constants to avoid typos (see L</CONSTANTS>).

=head3 dbic_fixture_class

See L<DBIx::Class::Migration::Script::Help::dbic_fixture_class>

=head3 dbic_fixtures_extra_args

See L<DBIx::Class::Migration::Script::Help::dbic_fixtures_extra_args>

=head3 dbic_connect_attrs

See L<DBIx::Class::Migration::Script::Help::dbic_connect_attrs>

=head3 dbi_connect_attrs

See L<DBIx::Class::Migration::Script::Help::dbi_connect_attrs>

=head3 extra_schemaloader_args

See L<DBIx::Class::Migration::Script::Help::extra_schemaloader_args>

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
on the commandline (via L<MooX::Options>) and run.

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

