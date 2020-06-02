package DBIx::Class::Migration;

our $VERSION = "0.075";
$VERSION = eval $VERSION;

use Moo;
use JSON::MaybeXS qw(JSON);
use File::Copy 'cp';
use File::Spec::Functions 'catdir', 'catfile', 'updir';
use File::Path 'mkpath', 'remove_tree';
use DBIx::Class::Migration::Types -all;
use Devel::PartialDump;
use SQL::Translator;
use Log::Any '$log', default_adapter => 'Stderr';
use Carp 'croak';

sub _log_die {
  my ($msg) = @_;
  $log->error($msg);
  croak $msg;
}

has db_sandbox_class => (
  is => 'ro',
  default => 'DBIx::Class::Migration::SqliteSandbox',
  isa => LoadableClass,
);

has db_sandbox => (is=>'lazy');

has db_sandbox_dir => (is=>'ro', predicate=>'has_db_sandbox_dir', isa=>Str);

has db_sandbox_builder_class => (
  is => 'lazy',
  isa => LoadableClass,
);

  sub _build_db_sandbox_builder_class {
    my $self = shift;
    return $self->has_db_sandbox_dir ?
      'DBIx::Class::Migration::SandboxDirSandboxBuilder' :
        'DBIx::Class::Migration::TargetDirSandboxBuilder';
  }

has db_sandbox_builder => (is=>'lazy');

  sub _build_db_sandbox_builder {
    my $self = shift;
    $self->db_sandbox_builder_class
      ->new(migration=>$self);
  }

  sub _build_db_sandbox {
    shift->db_sandbox_builder->build;
  }

has schema_class => (
  is => 'ro',
  predicate=>'has_schema_class',
  required=>0,
  isa => LoadableDBICSchemaClass,
  coerce=>1);

has schema_args => (is=>'lazy', isa=>ArrayRef);

  sub _build_schema_args {
    +[ shift->db_sandbox->make_sandbox ];
  }

has schema => (is=>'lazy', predicate=>'has_schema');

  sub _build_schema {
    my ($self) = @_;
    $self->schema_class->connect(@{$self->schema_args});
  }

has target_dir_builder_class => (
  is => 'ro',
  default => 'DBIx::Class::Migration::ShareDirBuilder',
  isa => LoadableClass,
);

has target_dir_builder => (is => 'lazy');

  sub _infer_schema_class {
    my $self = shift;
    return $self->has_schema_class ?
      $self->schema_class : $self->has_schema ?
        ref($self->schema) :
          _log_die "Can't infer schema class without a --schema or --schema_class";
  }

  sub _build_target_dir_builder {
    my $inferred_schema_class = (my $self = shift)
      ->_infer_schema_class;
    $self->target_dir_builder_class
      ->new(schema_class=>$inferred_schema_class);
  }

has target_dir => (is => 'lazy', isa=> AbsolutePath, coerce => 1);

  sub _build_target_dir {
    shift->target_dir_builder->build;
  }

has dbic_dh_args => (
  is=>'rw', isa=>HashRef,
  lazy => 1, builder => '_build_dbic_dh_args',
);

  sub _build_dbic_dh_args {
    +{ sql_translator_args => { quote_identifiers => 1 } }
  }

has schema_loader_class => (
  is => 'ro',
  default => 'DBIx::Class::Migration::SchemaLoader',
  isa => LoadableClass,
);

has schema_loader => (is=>'lazy');

  sub _build_schema_loader {
    my $self = shift;
    $self->schema_loader_class->new(
      schema=>$self->schema);
  }

has dbic_fixture_class => (
  is => 'ro',
  default => 'DBIx::Class::Fixtures',
  isa => LoadableClass,
);

has dbic_fixtures_extra_args => (is=>'lazy', isa=>HashRef);

  sub _build_dbic_fixtures_extra_args {
    return +{};
  }

has deployment_handler_class => (
  is => 'ro',
  default => 'DBIx::Class::DeploymentHandler',
  isa => LoadableClass,
);

has extra_schemaloader_args => (is=>'lazy', isa=>HashRef);

  sub _build_extra_schemaloader_args {
    return +{};
  }

  sub _infer_database_from_storage {
    return (ref(shift) =~m/DBI::(.+)$/)[0];
  }

  sub _normalize_inferred_storage {
    my $inferred_storage = shift;
    return 'MySQL' if $inferred_storage eq 'mysql';
    return 'PostgreSQL' if $inferred_storage eq 'Pg';
    return $inferred_storage;
  }

  sub _infer_database_from_schema {
    (my $storage = shift->storage)
      ->ensure_connected;
    if(my $inferred_storage = _infer_database_from_storage($storage)) {
      return _normalize_inferred_storage($inferred_storage);
    } else {
      print "Cannot infer target database, defaulting to SQLite\n";
      return 'SQLite';
    }
  }

sub normalized_dbic_dh_args {
  my $self = shift;
  my %args = %{$self->dbic_dh_args};
  unless($args{databases}) {
    $args{databases} = [_infer_database_from_schema($self->schema)];
    $self->dbic_dh_args(\%args); ## Cache the normalization for next run
  }

  return %{$self->dbic_dh_args};
}

sub dbic_dh {
  my ($self, @args) = @_;
  my %dbic_dh_args = $self->normalized_dbic_dh_args;

  _log_die "A \$VERSION needs to be specified in your schema class ${\$self->_infer_schema_class}"
  unless $self->schema->schema_version;

  my $dh = $self->deployment_handler_class->new({
    schema => $self->schema,
    %dbic_dh_args, @args,
    script_directory => catdir($self->target_dir, 'migrations'),
  });

  return $dh;
}

sub prepare_install { shift->dbic_dh->prepare_install }
sub prepare_upgrade { shift->dbic_dh->prepare_upgrade }
sub prepare_downgrade { shift->dbic_dh->prepare_downgrade }
sub install { shift->dbic_dh->install }
sub upgrade { shift->dbic_dh->upgrade }

sub downgrade {
  my ($self, %args) = @_;
  unless($self->dbic_dh_args->{to_version}) {
    my $to_version = $self->dbic_dh->schema_version;
    $to_version = $to_version->numify if ref $to_version; # version object
    $to_version -= 1;
    warn "No to_version is specified, downgrading to version $to_version";
    $args{to_version} = $to_version;
  }
  return $self->dbic_dh(%args)->downgrade;
}


before 'downgrade', sub {
  my ($self, $args) = @_;
};


sub dump { Devel::PartialDump->new->dump(shift) }

sub version { print "Application version is $VERSION\n" }

sub status {
  my $dbic_dh = shift->dbic_dh;
  print "Schema is ${\$dbic_dh->schema_version}\n";
  if($dbic_dh->version_storage_is_installed) {
    print "Deployed database is ${\$dbic_dh->database_version}\n";
  } else {
    print "Database is not currently installed\n";
  }
}

sub _create_file_at_path {
  my ($path, $data) = @_;
  open(my $fh, '>', $path)
    || _log_die "Can't create $path: $!";
  print $fh $data;
  close $fh;
}

sub _sets_data_from_sources {
  map { +{
    class=> $_,
    quantity => "all",
  } } @_;
}

sub _create_all_fixture_config_from_sources {
  JSON->new->pretty(1)->encode({
    "belongs_to" => { "fetch" => 0 },
    "has_many" => { "fetch" => 0 },
    "might_have" => { "fetch" => 0 },
    "sets" => [ _sets_data_from_sources(@_) ],
  });
}

sub _filter_private_sources { grep {$_!~/^__/} @_ }

sub _filter_views {
    my ($self, @sources) = @_;
    grep { ref($self->schema->source($_)) !~ m/View$/ } @sources;
}

sub _prepare_fixture_conf_dir {
  my ($dir, $version) = @_;
  my $fixture_conf_dir = catdir($dir,
    'fixtures', $version, 'conf');

  mkpath($fixture_conf_dir)
    unless -d $fixture_conf_dir;

  return $fixture_conf_dir;
}

sub _create_all_fixture_set {
  my $path = shift;
  my $conf = _create_all_fixture_config_from_sources(@_);
  _create_file_at_path($path, $conf);
}

sub _has_previous_version {
  return 0 if !$_[0];
  return $_[0]->numify - 1 if ref $_[0]; # version object
  $_[0]-1
}

sub _only_from_when_not_to {
  my ($from_dir, $to_dir) = @_;
  grep {
    not -e catfile($to_dir, ($_ =~ /\/([^\/]+)$/))
  } <$from_dir/*>;
}

sub _copy_from_to {
  my ($from_dir, $to_dir) = @_;
  print "Copying Fixture Confs from $from_dir to $to_dir\n";
  (cp($_, $to_dir)
    || _log_die "Could not copy $_: $!")
      for _only_from_when_not_to($from_dir, $to_dir);
}

sub prepare_up_down_grades {
  my ($self, $previous, $schema_version) = @_;
  $self->dbic_dh->version_storage_is_installed
    || _log_die "No Database to create up or downgrades from!";

  if($self->dbic_dh->database_version < $schema_version) {
    $self->prepare_upgrade;
    $self->prepare_downgrade;
  } else {
      print "Your Database version must be lower than than your schema version\n";
      print "in order to prepare upgrades / downgrades\n";
  }
}

sub prepare {
  my $self = shift;
  my $schema_version = $self->dbic_dh->schema_version
    || _log_die "Your Schema has no version!";

  $self->prepare_install;
  my $fixture_conf_dir = _prepare_fixture_conf_dir(
    $self->target_dir, $schema_version);

  my @sources = _filter_private_sources($self->schema->sources);
  my @real_tables = $self->_filter_views(@sources);
  my $all_tables_path = catfile($fixture_conf_dir,'all_tables.json');
  _create_all_fixture_set($all_tables_path, @real_tables);

  if(my $previous = _has_previous_version($schema_version)) {
    $self->prepare_up_down_grades($previous, $schema_version);
    my $previous_fixtures_conf = _prepare_fixture_conf_dir(
      $self->target_dir, $previous);
    _copy_from_to($previous_fixtures_conf, $fixture_conf_dir);
  } else {
    print "There is no current database deployed, so I can't prepare upgrades\n";
    print "or downgrades\n";
  }
}

sub drop_tables {
  my $self = shift;
  my $schema = $self->_schema_from_database;

  $schema->storage->with_deferred_fk_checks(sub {
    foreach my $source ($schema->sources) {
      my $table = $schema->source($source)->name;
      print "Dropping table $table\n";
      my $tableq = $schema->storage->dbh->quote_identifier($table);
      if(ref($schema->storage) =~m/Pg$/) {
        $schema->storage->dbh->do("drop table $tableq CASCADE");
      } else {
        $schema->storage->dbh->do("drop table $tableq");
      }
    }
  });
}

sub delete_table_rows {
  my $self = shift;
  my $schema = $self->_schema_from_database;

  $schema->storage->with_deferred_fk_checks(sub {
    my $txn = $schema->txn_scope_guard;
    foreach my $source ($schema->sources) {
      next if ($source eq 'DbixClassDeploymenthandlerVersion' ||
        $source =~ m/^__/);
      $schema->resultset($source)->delete;
    }
    $txn->commit;
  });
}

sub _prepare_fixture_data_dir {
  my ($dir, $version, $set) = @_;
  my $fixture_conf_dir = catdir($dir, 'fixtures', $version, $set);
  mkpath($fixture_conf_dir)
    unless -d $fixture_conf_dir;
  return $fixture_conf_dir;
}

sub build_dbic_fixtures_init_args {
  my $self = shift;
  my $version = $self->dbic_dh_args->{to_version};
  $version ||= $self->dbic_dh->version_storage_is_installed ?
    $self->dbic_dh->database_version : do {
      print "Since this database is not versioned, we will assume version ";
      print "${\$self->dbic_dh->schema_version}\n";
      $self->dbic_dh->schema_version;
    };

  my $conf_dir = _prepare_fixture_conf_dir($self->target_dir, $version);

  print "Reading configurations from $conf_dir\n";

  return {
    config_dir => $conf_dir,
    debug => ($ENV{DBIC_MIGRATION_DEBUG}||0),
    %{$self->dbic_fixtures_extra_args}};
}

sub build_dbic_fixtures {
  my $dbic_fixtures = (my $self = shift)->dbic_fixture_class;
  $dbic_fixtures->new($self->build_dbic_fixtures_init_args);
}

sub _schema_from_database {
  my $self = shift;
  my $schema = $self->schema_loader
    ->schema_from_database(
      $self->_infer_schema_class,
      %{$self->extra_schemaloader_args});
  # SQL_IDENTIFIER_QUOTE_CHAR
  $schema->storage->sql_maker->quote_char($schema->storage->dbh->get_info(29));
  $schema;
}

sub dump_named_sets {
  (my $self = shift)->dbic_dh->version_storage_is_installed
    || print "Target DB is not versioned.  Dump may not be reliable.\n";

  my $schema = $self->_schema_from_database;

  $self->build_dbic_fixtures->dump_config_sets({
    schema => $schema,
    configs => [map { "$_.json" } @_],
    directory_template => sub {
      my ($fixture, $params, $set) = @_;
      $set =~s/\.json//;
      my $fixture_conf_dir = catfile($fixture->config_dir,updir,$set);
      mkpath($fixture_conf_dir)
        unless -d $fixture_conf_dir;
      return $fixture_conf_dir;
    },
  });
}

sub dump_all_sets {
  (my $self = shift)->dbic_dh->version_storage_is_installed
    || print "Target DB is not versioned.  Dump may not be reliable.\n";

  my $schema = $self->_schema_from_database;

  $self->build_dbic_fixtures->dump_all_config_sets({
    schema => $schema,
    directory_template => sub {
      my ($fixture, $params, $set) = @_;
      $set =~s/\.json//;
      my $fixture_conf_dir = catfile($fixture->config_dir,updir,$set);
      mkpath($fixture_conf_dir)
        unless -d $fixture_conf_dir;
      return $fixture_conf_dir;
    },
  });
}

sub delete_named_sets {
  my ($self, @sets) = @_;
  my $fixtures = $self->build_dbic_fixtures;
  my @paths = map { catfile($fixtures->config_dir,updir,$_) } @sets;
  foreach my $path (@paths) {
    $self->_delete_path($path);
  }
}

  sub _delete_path {
    my ($self, $path) = @_;
    return unless -d $path;
    print "Deleting $path \n";
    remove_tree($path);
  }


sub populate_set_to_schema {
  my ($self, $target_set, $schema) = @_;
  $self->build_dbic_fixtures->populate({
    no_deploy => 1,
    schema => $schema,
    directory => $target_set });

  print "Restored set $target_set to database\n";
}

sub populate {
  (my $self = shift)->dbic_dh->version_storage_is_installed
    || _log_die "No Database to populate!";

  my $version = $self->dbic_dh->database_version;
  my $schema = $self->_schema_from_database;

  foreach my $set(@_) {
    my $target_set = _prepare_fixture_data_dir(
      $self->target_dir, $version, $set);
    $self->populate_set_to_schema($target_set, $schema);
  }
}

sub make_schema {
  (my $self = shift)->dbic_dh->version_storage_is_installed
    || _log_die "No Database to make Schema from!";
  my $schema = $self->schema_loader
    ->generate_dump(
      $self->_infer_schema_class,
      catdir($self->target_dir, 'dumped_db'));
}

sub diagram {
  my $self = shift;
  my $number_tables = scalar $self->schema->sources;
  my $dimension = int sqrt($number_tables * 13);
  my $trans = SQL::Translator->new(
    parser => 'SQL::Translator::Parser::DBIx::Class',
    parser_args => { dbic_schema => $self->schema },
    producer => 'GraphViz',
    producer_args => {
      skip_tables => 'dbix_class_deploymenthandler_versions',
      width => $dimension,
      height => $dimension,
      show_constraints => 1,
      show_datatypes => 1,
      show_sizes => 1,
      out_file  => $self->_diagram_default_outfile });

  $trans->translate
    or _log_die $trans->error;
}

  sub _diagram_default_outfile {
    my $self = shift;
    catfile $self->target_dir, 'db-diagram-v' . $self->dbic_dh->schema_version . '.png';
  }

sub install_if_needed {
  my ($self, %callbacks) = @_;
  if(!$self->dbic_dh->version_storage_is_installed) {
    $self->install;
    if(my $on_install = delete($callbacks{on_install})) {
      $on_install->($self->schema, $self);
    } elsif( my $default_fixture_sets = delete($callbacks{default_fixture_sets})) {
      $self->populate(@$default_fixture_sets);
    }
  }
}

sub install_version_storage {
  my $self = shift;
  if(!$self->dbic_dh->version_storage_is_installed) {
    $self->dbic_dh->install_version_storage;
    $self->dbic_dh->add_database_version({ version => $self->dbic_dh->schema_version });
    print "Version storage has been installed in the target database\n";
  } else {
    print "Version storage is already installed in the target database!\n";
  }
}

before [qw/install upgrade downgrade/], sub {
  my ($self, @args) = @_;
  %ENV = (
    %ENV,
    DBIC_MIGRATION_FIXTURES_CLASS => $self->dbic_fixture_class,
    DBIC_MIGRATION_FIXTURES_INIT_ARGS => JSON::MaybeXS->new->encode($self->build_dbic_fixtures_init_args),
    DBIC_MIGRATION_SCHEMA_CLASS => $self->schema_class,
    DBIC_MIGRATION_TARGET_DIR => $self->target_dir,
    DBIC_MIGRATION_FIXTURE_DIR => catdir($self->target_dir, 'fixtures', $self->dbic_dh->schema_version),
    DBIC_MIGRATION_SCHEMA_VERSION => $self->dbic_dh->schema_version,
    DBIC_MIGRATION_TO_VERSION => $self->dbic_dh->to_version,
    DBIC_MIGRATION_DATABASE_VERSION => (
      $self->dbic_dh->version_storage_is_installed ? $self->dbic_dh->database_version : 0),
  );
};

# We need to explicitly disconnect so that we can properly
# shutdown some databases (like Postgresql) without generating
# errors in cleanup.  Basically if we don't disconnect we often
# end up with blocking commands running on the server at the time
# we are trying to shut it down.

sub DEMOLISH {
  my $self = shift;
  return unless $self->has_schema && $self->schema;
  if(my $storage = $self->schema->storage) {
    $storage->disconnect;
  }
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

DBIx::Class::Migration - Use the best tools together for sane database migrations

=head1 SYNOPSIS

    use DBIx::Class::Migration;

    my $migration = DBIx::Class::Migration->new(
      schema_class => 'MyApp::Schema',
      schema_args => \@connect_opts);

Alternatively:

    use DBIx::Class::Migration;
    use MyApp::Schema;

    my $migration = DBIx::Class::Migration->new(
      schema => MyApp::Schema->connect(@connect_opts));

Informational Commands:

    $migration->status;

Preparing and using Migrations:

    $migration->prepare;
    $migration->install;
    $migration->upgrade;
    $migration->downgrade;

Commands for working with Fixtures:

    $migration->dump_named_sets;
    $migration->dump_all_sets;
    $migration->populate;

Utility Commands:

    $migration->drop_tables;
    $migration->delete_table_rows;
    $migration->make_schema;
    $migration->install_if_needed;
    $migration->install_version_storage;
    $migration->diagram;

=head1 DESCRIPTION

L<DBIx::Class::DeploymentHandler> is a state of the art solution to the problem
of creating sane workflows for versioning L<DBIx::Class> managed database
projects.  However, since it is more of a toolkit for building custom versioning
and migration workflows than an expression of a particular migration practice,
it might not always be the most approachable tool.  If you are starting a new
L<DBIx::Class> project and you don't have a particular custom workflow need,
you might prefer to simply be given a reasonable clear and standard practice,
rather than a toolkit with a set of example scripts.

L<DBIx::Class::Migration> defines some logic which combines both
L<DBIx::Class::DeploymentHandler> and L<DBIx::Class::Fixtures>, along with
a standard tutorial, to give you a simple and straightforward approach to
solving the problem of how to best create database versions, migrations and
testing data.  Additionally it builds on tools like L<Test::mysqld> and
L<Test::Postgresql58> along with L<DBD::Sqlite> in order to assist you in quickly
creating a local development database sandbox.  It offers some integration
points to testing your database, via tools like L<Test::DBIx::Class> in order to
make testing your database driven logic less painful.  Lastly, we offer some
thoughts on good development patterns in using databases with application
frameworks like L<Catalyst>.

L<DBIx::Class::Migration> offers code and advice based on my experience of using
L<DBIx::Class> for several years, which hopefully can help you bootstrap a new
project.  The solutions given should work for you if you want to use L<DBIx::Class>
and have database migrations, but don't really know what to do next.  These
solutions should scale upward from a small project to a medium project involving
many developers and more than one target environment (DEV -> QA -> Production.)
If you have very complex database versioning requirements, huge teams and
difficult architectual issues, you might be better off building something on
top of L<DBIx::Class::DeploymentHandler> directly.

L<DBIx::Class::Migration> is a base class upon which interfaces like
L<DBIx::Class::Migration::Script> are built.

Please see L<DBIx::Class::Migration::Tutorial> for more approachable
documentation.  If you want to read a high level feature overview, see
L<DBIx::Class::Migration::Features>.  The remainder of this POD is API level
documentation on the various internals.

=head1 ATTRIBUTES

This class defines the following attributes.

=head2 db_sandbox_builder_class

Accept Str.  Defaults to 'DBIx::Class::Migration::TargetDirSandboxBuilder'

The name of the helper class which builds the class that builds database
sandboxs.  By default we build database sandboxes in the L</target_dir>, which
is what L<DBIx::Class::Migration::TargetDirSandboxBuilder> does.  We can also
build database sandboxes in a temporary directory using
L<DBIx::Class::Migration::TempDirSandboxBuilder>.  You might prefer that for
running tests, for example.

=head2 db_sandbox_class

Accepts Str.  Not Required (defaults to 'DBIx::Class::Migration::SqliteSandbox').

Unless you already have a database setup and running (as you probably do in
production) we need to auto create a database 'sandbox' that is isolated to
your development local.  This class is a delegate that performs this job if you
don't want to go to the trouble of installing and setting up a local database
yourself.

This must point to a class that expects C<target_dir> and C<schema_class> for
initialization arguments and must define a method C<make_sandbox> that returns
an array which can be sent to L<DBIx::Class::Schema/connect>.

This defaults to L<DBIx::Class::Migration::SqliteSandbox>.  Currently we have
support for MySQL and Postgresql via L<DBIx::Class::Migration::MySQLSandbox>
and L<DBIx::Class::Migration::PgSandbox>, but you will need to side install
L<Test::mysqld> and L<Test::Postgresql58> (In other words you'd need to add
these C<Test::*> namespace modules to your C<Makefile.PL> or C<dist.ini>).

=head2 db_sandbox

Accepts: Object.  Not required.

This is an instantiated object as defined by L</db_sandbox_class>.  It is a
delegate for the work of automatically creating a local database sandbox that
is useful for developers and for quickly bootstrapping a project.

=head2 schema_class

Accepts Str.  Not Required (but if missing, you need to populate L</schema>).

This is the schema we use as the basis for creating, managing and running your
deployments.  This should be the full package namespace defining your subclass
of L<DBIx::Class::Schema>.  For example C<MyApp::Schema>.

If the L</schema_class> cannot be loaded, a hard exception will be thrown.

=head2 schema_args

Accepts ArrayRef.  Required but lazily builds from defaults

Provides arguments passed to C<connect> on your L</schema_class>.  Should
connect to a database.

This is an arrayref that would work the same as L<DBIx::Class::Schema/connect>.
If you choose to create an instance of L<DBIx::Class::Migration> by providing a
L<schema_class>, you can use this to customize how we connect to a database.

If you don't provide a value, we will automatically create a SQLite based
database connection with the following DSN:

    DBD:SQLite:[path to target_dir]/[db_file_name].db

Where C<[path to target_dir]> is L</target_dir> and [db_file_name] is a converted
version of L</schema_class>.  For example if you set L<schema_class> to:

    MyApp::Schema

Then [db_file_name] would be C<myapp-schema>.

Basically, this means you can start testing your database designs right off
without a lot of effort, just point at a L<schema_class> and get deploying!

=head2 schema

Accepts: Object of L<DBIx::Class::Schema>.  Not required.

If you already have a connected schema (subclass of L<DBIx::Class::Schema>)
you can simple point to it, skipping L<schema_class> and L<schema_args>.  You
might for example be using L<Catalyst> and want to build deployments for a
database that is listed in configuration:

    use MyCatalyst::App;
    use DBIx::Class::Migration;

    my $migration = DBIx::Class::Migration->new(
      schema => MyCatalyst::App->model('Schema')->schema,
      %{MyCatalyst::App->config->{extra_migration_init_args}};
    );

=head2 target_dir_builder_class

Accepts:  Str, Defaults to 'DBIx::Class::Migration::ShareDirBuilder'
This is a class that is used as a helper to build L</target_dir> should the
user not provide a value.  Default is L<DBIx::Class::Migration::ShareDirBuilder>

=head2 target_dir_builder

An instance of whatever is in L</target_dir_builder_class>.  Used by the lazy
build method of L</target_dir> to default a directory where the migrations are
actually placed.

=head2 target_dir

Accepts Str.  Required (lazy builds to your distribution C</share> directory).

This is the directory we store our migration and fixture files.  Inside this
directory we will create a C<fixtures> and C<migrations> sub-directory.

Although you can specify the directory, if you leave it undefined, we will use
L<File::ShareDir::ProjectDistDir> to locate the C</share> directory for your
project and place the files there.  This is the recommended approach, and is
considered a community practice in regards to where to store your distribution
non code files.  Please see L<File::ShareDir::ProjectDistDir> as well as
L<File::ShareDir> for more information.

This uses whatever is in L</schema_class> to determine your project (and look
for a C<share> directory, which you'll need to create in your project root).
If you don't have a L</schema_class> defined, you must have a L</schema>,
and we'll infer the class via C<< ref($self->schema) >>.

B<NOTE:> You'll need to make the C</share> directory if you are going to use
the default option.  We don't automatically create it for you.

=head2 schema_loader_class

Accepts Str.  Required

Because your application subclass of L<DBIx::Class::Schema> is going to
change a lot, sometimes we need to generate our own schema and get one that is
in a known, good state.  Mostly this is used by the commands to drop tables
and clear tables.

Defaults to L<DBIx::Class::Migration::SchemaLoader>.  You'll probably only
need to change this if your database is crazy and you need to massage the
init arguments to L<DBIx::Class::Schema::Loader>.

=head2 schema_loader

Accepts Object.  Required but lazy builds.

This is a factory that provider autoloaded schema based on the current schema's
database.  It is automatically created and you are unlikely to need to set this
manually.

=head2 dbic_fixture_class

Accepts Str.  Required

This is the class we use when creating instances of L<DBIx::Class::Fixtures>.
You'll probably need to review the docs for that and understand how configuration
rules work in order to best take advantage of the system.

Defaults to L<DBIx::Class::Fixtures>.  You'll probably not need to change this
unless you have some unusual needs regarding fixtures.

=head2 dbic_fixtures_extra_args

Accepts HashRef. Required, but Defaults to Empty Hashref

Allows you to pass some additional arguments when creating instances of
L</dbic_fixture_class>.  These arguments can be used to override the default
initial arguments.

=head2 deployment_handler_class

Accepts Str.  Required

This is the class we use when creating instances of L<DBIx::Class::DeploymentHandler>.
It would be ideal that you review those docs in order to better understand the
overall architecture of the system.

Defaults to L<DBIx::Class::DeploymentHandler>.  You'll probably not need to
change this unless you need a custom deployment handler, and if you do, I
can't be sure this framework will work correctly, particularly if you are not
using monotonic versioning.

=head2 dbic_dh_args

Accepts HashRef.  Required and defaults to a hashref setting
C<sql_translator_args>'s C<quote_identifiers> to a true value, which
despite being documented as the default, is not the case in practice.

Used to pass custom args when building a L<DBIx::Class::DeploymentHandler>.
Please see the docs for that class for more.  Useful args might be C<databases>,
C<to_version> and C<force_overwrite>.

=head2 dbic_dh

Accepts Instance of L<DBIx::Class::DeploymentHandler>.  Required but lazily
built from default data and L<dbic_dh_args>.

You probably won't need to build your own deployment handler and pass it in
(unlike L<schema>, where it might actually be useful).  Be careful it you do
since this framework makes some assumptions about your deployment handler (for
example we assume you are using the monotonic versioning).

When this attribute is lazily built, we merge L</dbic_dh_args> with the
following defaults:

      schema => Points to $self->schema
      script_directory => Points to catdir($self->target_dir, 'migrations')
      databases => Inferred from your connected schema, defaults to SQLite

L</dbic_dh_args> will overwrite the defaults, if you pass them.

=head2 extra_schemaloader_args

Optional.  Accepts a HashRef of arguments you can use to influence how
L<DBIx::Class::Schema::Loader> works.  This HashRef would get passed as
C<loader_options> (see L<DBIx::Class::Schema::Loader/make_schema_at>.

Meaningful options are described at L<DBIx::Class::Schema::Loader::Base>.

=head1 METHODS

This class defines the following methods for public use

=head2 new

Used to create an new instance of L<DBIx::Class::Migration>.  There's a couple
of paths to creating this instance.

=head3 Specify a schema_class and optionally schema_args

    use DBIx::Class::Migration;
    my $migration = DBIx::Class::Migration->new(
      schema_class => 'MyApp::Schema',
      schema_args => [@connect_info],
    );

This is probably the most general approach, and is recommended unless you
already have a connected instance of your L<DBIx::Class::Schema> subclass.

L</schema_args> would be anything you'd pass to L<DBIx::Class::Schema/connect>.
see L</schema_args> for how we construct default connect information if you
choose to leave this undefined.

=head3 Specify a schema

There may be some cases when you already have a schema object constructed and
would prefer to just use that.  For example, you may be using L<Catalyst> and
wish to build custom scripts using the built-in dependency and service lookup:

    use MyCatalyst::App;
    use DBIx::Class::Migration;

    my $migration = DBIx::Class::Migration->new(
      schema => MyCatalyst::App->model('Schema')->schema,
      %{MyCatalyst::App->config->{extra_migration_init_args}};
    );

Be careful of potential locking issues when using some databases like SQLite.

=head3 OPTIONAL: Specify a target_dir

Optionally, you can specify your migrations target directory (where your
migrations get created), in your init arguments.  This option can be combined
with either approach listed above.

    use DBIx::Class::Migration;
    my $migration = DBIx::Class::Migration->new(
      schema_class => 'MyApp::Schema',
      schema_args => [@connect_info],
      target_dir => '/opt/database-migrations',
    );

If you leave this undefined we default to using the C<share> directory in your
distribution root.  This is generally the community supported place for non
code data, but if you have huge fixture sets you might wish to place them in
an alternative location.

=head3 OPTIONAL: Specify a db_sandbox_dir

Be default if you allow for a local database sandbox (as you might during early
development and you don't want to work to make a database) that sandbox gets
built in the 'target_dir'.  Since other bits in the target_dir are probably
going to be in your project repository and the sandbox generally isnt, you
might wish to build the sandbox in an alternative location.  This setting
allows that:

    use DBIx::Class::Migration;
    my $migration = DBIx::Class::Migration->new(
      schema_class => 'MyApp::Schema',
      schema_args => [@connect_info],
      db_sandbox_dir => '~/opt/database-sandbox',
    );

This then gives you a nice totally standalone database sandbox which you can
reuse for other projects, etc.

=head3 OPTIONAL: Specify dbic_dh_args

Optionally, you can specify additional arguments to the constructor for the
L</dbic_dh> attribute.  Useful arguments might include additional C<databases>
we should build fixtures for, C<to_version> and C<force_overwrite>.

See L<DBIx::Class::DeploymentHandler/> for more information on supported init
arguments.  See L</dbic_dh> for how we merge default arguments with your custom
arguments.

=head3 Other Initial Arguments

For normal usage the remaining init args are probably not particularly useful
and reflect a desire for long term code flexibility and clean design.

=head2 version

Prints to STDOUT a message regarding the version of L<DBIC:Migration> that you
are currently running.

=head2 status

Returns the state of the deployed database (if it is deployed) and the state
of the current C<schema> version.  Sends this as a string to STDOUT

=head2 prepare

Creates a C<fixtures> and C<migrations> directory under L</target_dir> (if they
don't already exist) and makes deployment files for the current schema.  If
deployment files exist, will fail unless you L</overwrite_migrations>.

The C<migrations> directory reflects a directory structure as documented in
L<DBIx::Class::DeploymentHandler>.

If this is the first version, we create directories and initial DLL, etc.  For
versions greater than 1, we will also generate diffs and copy any fixture
configs etc (as well as generating a fresh 'all_table.json' fixture config). For
safety reasons, we never overwrite any fixture configs.

=head2 install

Installs either the current schema version (if already prepared) or the target
version specified via any C<to_version> flags sent as an L<dbic_dh_args> to the
database which is connected via L</schema>.

If you try to install to a database that has already been installed, you'll get
an error.  See L</drop_tables>.

=head2 upgrade

Run upgrade files to bring the database into sync with the current schema
version.

=head2 downgrade

Run down files to bring the database down to the previous version from what is
installed to the database

=head2 drop_tables

Drops all the tables in the connected database with no backup or recovery.  For
real! (Make sure you are not connected to Prod, for example).

=head2 delete_table_rows

Does a C<delete> on each table in the database, which clears out all your data
but preserves tables.  For Real!  You might want this if you need to load
and unload fixture sets during testing, or perhaps to get rid of data that
accumulated in the database while running an app in development, before dumping
fixtures.

=head2 dump_named_sets

Given an array of fixture set names, dump them for the current database version.

=head2 dump_all_sets

Takes no arguments just dumps all the sets we can find for the current database
version.

=head2 make_schema

Given an existing database, reverse engineer a L<DBIx::Class> Schema in the
L</target_dir> (under C<dumped_db>).  You can use this if you need to bootstrap
your DBIC files.

=head2 populate

Given an array of fixture set names, populate the current database version with
the matching sets for that version.

Skips the table C<dbix_class_deploymenthandler_versions>, so you don't lose
deployment info (this is different from L</drop_tables> which does delete it.)

=head2 diagram

Experimental feature.  Although not specifically a migration task, I find it
useful to output visuals of my databases.  This command will place a file in
your L</target_dir> called C<db-diagram-vXXX.png> where C<XXX> is he current
C<schema> version.

This is using the Graphviz producer (L<SQL::Translator::Producer::GraphViz>)
which in turn requires L<Graphviz>.  Since this is not always trivial to
install, I do not require it.  You will need to add it manually to your
C<Makefile.PL> or C<dist.ini> and manage it yourself.

This feature is experimental and currently does not offer any options, as I
am still determining the best way to meet the need without exceeding the
scope of L<DBIx::Class::Migration>.  Consider this command a 'freebee' and
please don't depend on it in your custom code.

=head2 install_if_needed

If the database is not installed, do so.  Accepts a hash of callbacks or
instructions to perform should installation be needed/

    $migration->install_if_needed(
      on_install => sub {
        my ($schema, $local_migration) = @_;
        DBIx::Class::Migration::Population->new(
          schema=>shift)->populate('all_tables');
      });

The following callbacks / instructions are permitted

=over 4

=item on_install

Accepts: Coderef

Given a coderef, execute it after the database is installed.  The coderef
gets passed two arguments: C<$schema> and C<$self> (the current migration
object).

=item default_fixture_sets

Accepts: Arrayref of fixture sets

    $migration->install_if_needed(
      default_fixture_sets => ['all_tables']);

After database installation, populate the fixtures in order.

=back

=head2 install_version_storage

If the targeted (connected) database does not have the versioning tables
installed, this will install them.  The version is set to whatever your
C<schema> version currently is.

You will only need to use this command in the case where you have an existing
database that you are reverse engineering and you need to setup versioning
storage since you can't rebuild the database from scratch (such as if you have
a huge production database that you now want to start versioning).

=head2 delete_named_sets

Given a (or a list) of fixture sets, delete them if the exist in the current
schema version.

Yes, this really deletes, you've been warned (check in your code to a source
control repository).

=head1 ENVIRONMENT

When running L<DBIx::Class::Migration> we set some C<%ENV> variables during
installation, up / downgrading, so that your Perl run scripts (see
L<DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator\'PERL SCRIPTS'>)
can receive some useful information.  The Following C<%ENV> variables are set:

    DBIC_MIGRATION_SCHEMA_CLASS => $self->schema_class
    DBIC_MIGRATION_TARGET_DIR => $self->target_dir
    DBIC_MIGRATION_FIXTURE_DIR => catdir($self->target_dir, 'fixtures', $self->dbic_dh->schema_version),
    DBIC_MIGRATION_SCHEMA_VERSION => $self->dbic_dh->schema_version
    DBIC_MIGRATION_TO_VERSION => $self->dbic_dh->to_version
    DBIC_MIGRATION_DATABASE_VERSION => $self->dbic_dh->schema_version || 0

You might find having these available in your migration scripts useful for
doing things like 'populate a database from a fixture set, if it exists, but
if not run a bunch of inserts.

=head1 THANKS

Because of the awesomeness of CPAN and the work of many others, all this
functionality is provided with a few hundred lines of code.  In fact, I spent
a lot more time writing docs and tests than anything else. Here are some
particular projects / people I'd like to thank:

First, thanks to C<mst> for providing me a big chunk of code that served to
kickstart my work, and served as an valuable prototype.

Thanks to C<frew> for the awesome L<DBIx::Class::DeploymentHandler> which gives
us such a powerful base for organizing database versions.  Thanks to all the
authors of L<DBIx::Class::Fixtures> for giving me a foundation for managing
sets of data.  Lastly, thanks to the L<DBIx::Class> cabal for all the work done
in making the L<DBIx::Class> ORM so amazingly powerful.

Additionally thanks to the creators / maintainers for L<Test::mysqld> and
L<Test::Postgresql58>, which made it easy to create developer level sandboxes for
these popular open source databases.

As usual, thanks to the L<Moose> cabal for making Perl programming fun and
beautiful.  Lastly, a shout-out to the L<Dist::Zilla> cabal for making it so I
don't need to write my own build and deployment tools.

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>

=head1 CONTRIBUTORS

The following is a list of identified contributors.  Please let me know if I
missed you.

    https://github.com/pjcj
    https://github.com/chromatic
    https://github.com/bentglasstube
    https://github.com/logie17
    https://github.com/RsrchBoy
    https://github.com/vkroll
    https://github.com/felliott
    https://github.com/mkrull
    https://github.com/moltar
    https://github.com/andyjones
    https://github.com/pnu
    https://github.com/n7st
    https://github.com/willsheppard
    https://github.com/mulletboy2
    https://github.com/mohawk2
    https://github.com/manwar
    https://github.com/upasana-me
    https://github.com/rabbiveesh

=head1 SEE ALSO

L<DBIx::Class::DeploymentHandler>, L<DBIx::Class::Fixtures>, L<DBIx::Class>,
L<DBIx::Class::Schema::Loader>, L<Moo>, L<DBIx::Class::Migration::Script>,
L<DBIx::Class::Migration::Population>, L<dbic-migration>, L<SQL::Translator>,
L<Test::mysqld>, L<Test::Postgresql58>.

=head1 COPYRIGHT & LICENSE

Copyright 2013-2015, John Napiorkowski L<email:jjnapiork@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

