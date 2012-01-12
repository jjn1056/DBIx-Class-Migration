package DBIx::Class::Migration;

our $VERSION = "0.001";

use Moose;
use JSON::XS;
use File::Copy 'cp';
use File::Spec::Functions 'catdir', 'catfile';
use File::Path 'mkpath', 'remove_tree';
use File::ShareDir::ProjectDistDir ();
use DBIx::Class::Migration::SchemaLoader;
use MooseX::Types::LoadableClass 'LoadableClass';
use Class::Load 'load_class';

has schema_class => (
  is => 'ro',
  predicate=>'has_schema_class',
  required=>0,
  isa => LoadableClass,
  coerce=>1);

has schema_args => (is=>'ro', isa=>'ArrayRef', lazy_build=>1);

  sub _generate_filename_for_default_db {
    my ($schema_class) = @_;
    $schema_class =~ s/::/-/g;
    return lc($schema_class);
  }

  sub _generate_dsn {
    my ($schema_class, $target_dir) = @_;
    my $filename = _generate_filename_for_default_db($schema_class);
    'DBI:SQLite:'. catfile($target_dir, "$filename.db");
  }

  sub _build_schema_args {
    my $self = shift;
    [ _generate_dsn($self->schema_class, $self->target_dir), '', '' ];
  }

has schema => (is=>'ro', lazy_build=>1, predicate=>'has_schema');

  sub _build_schema {
    my ($self) = @_;
    $self->schema_class->connect(@{$self->schema_args});
  }

has target_dir => (is=>'ro', lazy_build=>1);

  sub _infer_schema_class {
    my $self = shift;
    return $self->has_schema_class ?
      $self->schema_class : ref($self->schema);
  }

  sub _build_target_dir {
    my $self = shift;
    my $class = $self->_infer_schema_class;
    my $file_name = $class;
    $file_name =~s/::/\//g;

    File::ShareDir::ProjectDistDir->import('dist_dir',
      filename => $INC{$file_name.".pm"});

    $class =~s/::/-/g;
    my $target_dir = dist_dir($class);
    mkpath $target_dir unless -d $target_dir;
    return $target_dir;
  }

has dbic_dh_args => (is=>'ro', isa=>'HashRef', default=>sub { +{} });
has dbic_dh => (
  is => 'ro',
  init_arg =>  undef,
  lazy_build => 1,
  handles => [qw/
    prepare_install
    prepare_upgrade
    prepare_downgrade
    install
    upgrade
    downgrade/]);

has schema_loader_class => (
  is => 'ro',
  default => 'DBIx::Class::Migration::SchemaLoader',
  isa => LoadableClass,
  coerce=>1);

has schema_loader => (is=>'ro', lazy_build=>1);

  sub _build_schema_loader {
    my $self = shift;
    $self->schema_loader_class->new(schema=>$self->schema);
  }

has dbic_fixture_class => (
  is => 'ro',
  default => 'DBIx::Class::Fixtures',
  isa => LoadableClass,
  coerce=>1);

has deployment_handler_class => (
  is => 'ro',
  default => 'DBIx::Class::DeploymentHandler',
  isa => LoadableClass,
  coerce=>1);

  sub _infer_database_from_schema {
    my $storage = shift->storage;
    $storage->ensure_connected;
    my $storage_specific_class = ref($storage);
    my $inferred_storage = ($storage =~m/DBI::(.+)\=/)[0] || 'SQLite';
    $inferred_storage = 'MySQL' if $inferred_storage eq 'mysql'; #Ugg
    return $inferred_storage;
  }

  sub _build_dbic_dh {
    my $self = shift;
    my $databases = $self->dbic_dh_args->{databases} ?
      delete($self->dbic_dh_args->{databases}) :
      [_infer_database_from_schema($self->schema)];

    (load_class "SQL::Translator::Producer::$_" ||
      die "No SQLT Producer for $_") for @$databases;

    $self->deployment_handler_class->new({
      schema => $self->schema,
      script_directory => catdir($self->target_dir, 'migrations'),
      databases => $databases,
      %{$self->dbic_dh_args},
    })
  }

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
    || die "Can't create $path: $!";
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
  JSON::XS->new->pretty(1)->encode({
    "belongs_to" => { "fetch" => 0 },
    "has_many" => { "fetch" => 0 },
    "might_have" => { "fetch" => 0 },
    "sets" => [ _sets_data_from_sources(@_) ],
  });
}

sub _filter_private_sources { grep {$_!~/^__/} @_ }

sub _prepare_fixture_conf_dir {
  my ($dir, $version) = @_;
  my $fixture_conf_dir = catdir($dir, 'fixtures', $version, 'conf');
  mkpath($fixture_conf_dir)
    unless -d $fixture_conf_dir;
  return $fixture_conf_dir;
}

sub _create_all_fixture_set {
  my $path = shift;
  my $conf = _create_all_fixture_config_from_sources(@_);
  _create_file_at_path($path, $conf);
}

sub _has_previous_version { $_[0] ? $_[0]-1 : 0 }

sub _only_from_when_not_to {
  my ($from_dir, $to_dir) = @_;
  grep {
    not -e catfile($to_dir, ($_ =~ /\/([^\/]+)$/))
  } <$from_dir/*>;
}

sub _copy_from_to {
  my ($from_dir, $to_dir) = @_;
  (cp($_, $to_dir)
    || die "Could not copy $_: $!")
      for _only_from_when_not_to($from_dir, $to_dir);
}

sub prepare {
  my $self = shift;
  my $schema_version = $self->dbic_dh->schema_version
    || die "Your Schema has no version!";

  $self->prepare_install;

  my $fixture_conf_dir = _prepare_fixture_conf_dir(
    $self->target_dir, $schema_version);

  my @sources = _filter_private_sources($self->schema->sources);
  _create_all_fixture_set( catfile($fixture_conf_dir,'all_tables.json'), @sources);

  if(my $previous = _has_previous_version($schema_version)) {
    if($self->dbic_dh->version_storage_is_installed) {
      if($self->dbic_dh->database_version < $schema_version) {
        $self->prepare_upgrade;
        $self->prepare_downgrade;
      } else {
        print "Your Database version must be lower than than your schema version\n";
        print "in order to prepare upgrades / downgrades\n";
      }
    } else {
      print "There is not current database deployed, so I can't prepare upgrades\n";
      print "or downgrades\n";
    }

    my $previous_fixtures_conf = _prepare_fixture_conf_dir(
      $self->target_dir, $previous);

    _copy_from_to($fixture_conf_dir, $previous_fixtures_conf);
  }
}

sub drop_tables {
  my $self = shift;
  my $schema = $self->schema_loader
    ->schema_from_database($self->_infer_schema_class);

  $schema->storage->with_deferred_fk_checks(sub {
    my $txn = $schema->txn_scope_guard;
    foreach my $source ($schema->sources) {
      my $table = $schema->source($source)->name;
      print "Dropping table $table\n";
      $schema->storage->dbh->do("drop table $table");
    }
    $txn->commit;
  });
}

sub delete_table_rows {
  my $self = shift;
  my $schema = $self->schema_loader
    ->schema_from_database($self->_infer_schema_class);

  $schema->storage->with_deferred_fk_checks(sub {
    my $txn = $schema->txn_scope_guard;
    foreach my $source ($schema->sources) {
      next if $source eq 'DbixClassDeploymenthandlerVersion';
      next if $source =~ m/^__/;
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

sub build_dbic_fixtures {
    my $self = shift;
    my $dbic_fixtures = $self->dbic_fixture_class;
    my $conf_dir = _prepare_fixture_conf_dir($self->target_dir,
      $self->dbic_dh->database_version);

    print "Reading configurations from $conf_dir\n";
    $dbic_fixtures->new({
      config_dir => $conf_dir});
}

sub dump_named_sets {
  (my $self = shift)->dbic_dh->version_storage_is_installed
    || die "No Database to dump!";

  $self->build_dbic_fixtures->dump_config_sets({
    schema => $self->schema,
    configs => [map { "$_.json" } @_],
    directory_template => sub {
      my ($fixture, $params, $set) = @_;
      $set =~s/\.json//;
      _prepare_fixture_data_dir($self->target_dir,
        $self->dbic_dh->database_version, $set);
    },
  });
}

sub dump_all_sets {
  (my $self = shift)->dbic_dh->version_storage_is_installed
    || die "No Database to dump!";

  $self->build_dbic_fixtures->dump_all_config_sets({
    schema => $self->schema,
    directory_template => sub {
      my ($fixture, $params, $set) = @_;
      $set =~s/\.json//;
      _prepare_fixture_data_dir($self->target_dir,
        $self->dbic_dh->database_version, $set);
    },
  });
}

sub populate {
  (my $self = shift)->dbic_dh->version_storage_is_installed
    || die "No Database to dump!";
  my $version_to_populate = $self->dbic_dh->database_version ||
    $self->dbic_dh->to_version;

  foreach my $set(@_) {
    my $target_dir = _prepare_fixture_data_dir($self->target_dir,
      $version_to_populate, $set);

    $self->build_dbic_fixtures->populate({
      no_deploy => 1,
      schema => $self->schema,
      directory => $target_dir,
    });

    print "Restored set $set to database\n";
  }
}

sub make_schema {
  my $self = shift;
  my $schema = $self->schema_loader
    ->generate_dump(
      $self->_infer_schema_class,
      catdir($self->target_dir, 'dumped_db'));
}


__PACKAGE__->meta->make_immutable;

=head1 NAME

DBIx::Class::Migration - Make database migrations possible

=head1 SYNOPSIS

    use DBIx::Class::Migration;
    use MyApp::Schema;

    my $migration = DBIx::Class::Migration->new(
      schema_class => MyApp::Schema;
    );

    $migration->prepare;
    $migration->install;

=head1 DESCRIPTION

L<DBIx::Class::DeploymentHandler> is a state of the art solution to the problem
of creating sane workflows for versioning L<DBIx::Class> managed database
projects.  However, since it is more of a toolkit for building custom versioning
and migration workflows than an expression of a particular migration practice,
it might not always be the most approachable tool.  If you are starting a new
L<DBIx::Class> project and you don't have a particular custom workflow need,
you might prefer to simple be given a reasonable clear and standard practice,
rather than a toolkit with a set of example scripts.

L<DBIx::Class::Migration> defines some logic which combines both
L<DBIx::Class::DeploymentHandler> and L<DBIx::Class::Fixtures>, along with
a standard tutorial, to give you a simple and straightforward approach to
solving the problem of how to best create database versions, migrations and
testing data.  It offers code and advice based on my experience of using
L<DBIx::Class> for several years, which hopefully can help you bootstrap out of
the void.  The solutions given should work for you if you want to use L<DBIx::Class>
and have database migrations, but don't really know what to do next.  These
solutions should scale upward from a small project to a medium project involving
many developers and more than one target environment (DEV -> QA -> Production.)
If you have very complex database versioning requirements, huge teams and
difficult architectual issues, you might be better off building something on
top of L<DBIx::Class::DeploymentHandler> directly.

L<DBIx::Class::Migration> is a base class upon which interfaces like
L<DBIx::Class::Migration::Script> are built.  In the future hopefully there
will be other interfaces for particular needs, such as testing.

Please see L<DBIx::Class::Migration::Tutorial> for more approachable
documentation.  The remainder of this POD is API level documentation on the
various internals.

=head1 ATTRIBUTES

This class defines the following attributes.

=head2 schema_class

Accepts Str.  Not Required (but if missing, you need to populate L</schema>).

This is the schema we use as the basic for creating, managing and running your
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

Where c<[path to home_dir]> is L</target_dir> and [db_file_name] is a converted
version of L</schema_class>.  For example if you set L<schema_class> to:

    MyApp::Schema

Then [db_file_name] would be C<myapp-schema>.

Basically, this means you can start testing your database designs right off
without a lot of effort, just point at a L<schema_class> and get deploying!

=head2 schema

Accepts: Object of L<DBIx::Class::Schema>.  Not required.

If you already have a connected schema (subclass of L<DBIx::Class::Schema>)
you can simple point to it, skipping L<schema_class> and L<schema_args>.  You
might for example be using L<Catalyst> and want to build deployments for
database that are part of your configuration:

    use MyCatalyst::App;
    use DBIx::Class::Migration;

    my $migration = DBIx::Class::Migration->new(
      schema => MyCatalyst::App->model('Schema')->schema,
      %{MyCatalyst::App->config->{extra_migration_init_args}};
    );

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

This uses whatever is in L</schema_class> to determine your project (and look
for a C<share> directory, which you'll need to create in your project root).
If you dont' have a L</schema_class> defined, you must have a L</schema>,
and we'll infer the class via C<< ref($self->schema) >>.

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

This is a factory that provider autoloaded schema based on the current schema's
database.

=head2 dbic_fixture_class

Accepts Str.  Required

This is the class we use when creating instances of L<DBIx::Class::Fixtures>.
You'll probably need to review the docs for that and understand how configuration
rules work in order to best take advantage of the system.

Defaults to L<DBIx::Class::Fixtures>.  You'll probably not need to change this
unless you have some usual needs regarding fixtures.

=head2 deployment_handler_class

Accepts Str.  Required

This is the class we use when creating instances of L<DBIx::Class::DeploymentHandler>.
It would be ideal that you review those docs in order to better understand the
overall architecture of the system.

Defaults to L<DBIx::Class::DeploymentHandler>.  You'll probably not need to
change this unless you need a custom deployment handler, and if you do, I
can't be sure this framework will work correctly, particularly if you are not
useing monotonic versioning.

=head2 dbic_dh_args

Accepts HashRef.  Required and defaults to an empty hashref.

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
woudl prefer to just use that.  For example, you may be using L<Catalyst> and
wish to build custom scripts using the built-in dependency and service lookup:

    use MyCatalyst::App;
    use DBIx::Class::Migration;

    my $migration = DBIx::Class::Migration->new(
      schema => MyCatalyst::App->model('Schema')->schema,
      %{MyCatalyst::App->config->{extra_migration_init_args}};
    );

Be care of potential locking issues when using some databases like SQLite.

=head3 OPTIONAL: Specify a target_dir

Optionally, you can specify your migrations target directory (where your
migrations get created, in your init arguments.  This option can be combined
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

Prints to STDOUT a message regarding the current application $VERSION

=head2 status

Returns the state of the deployed database (if it is deployed) and the state
of the current C<schema> version.  Sends this as a string to STDOUT

=head2 prepare

Creates a C<fixtures> and C<migrations> directory under L</target_dir> (if they
don't already exist) and makes deployment files for the current schema.  If
deployment files exist, will fail unless you L</overwrite_migrations> and
L</overwrite_fixtures>.

The C<migrations> directory reflects a directory structure as documented in
L<DBIx::Class::DeploymentHandler>.

If this is the first version, we create directories and initial DLL, etc.  For
versions greater than 1, we will also generate diffs and copy any fixture
configs etc (as well as generating a fresh 'all_table.json' fixture config). For
safety reasons, we never overwrite any fixture configs.

=head2 install

Installs either the current schema version (if already prepared) or the target
version specified via any C<to_version> flags sent as an L<dbic_dh_args> to the
database which is connected via L</schema>

=head2 upgrade

Run upgrade files to bring the database into sync with the current schema
version.

=head2 downgrade

Run down files to bring the database down to the previous version from what is
installed to the database

=head2 drop_tables

Drops all the tables in the connected database with no backup or recovery.  For
real! (Make sure you are not connected to Prod, for example)

=head2 delete_table_rows

does a C<delete> on each table in the database, which clears out all your data
but preserves tables.  For Real!  You might want this if you need to load
and unload fixture sets during testing, or perhaps to get rid of data that
accumulated in the database while running an app in development, before dumping
fixtures.

=head2 dump_named_sets

Given an array of set names, dump them for the current database version

=head2 dump_all_sets

Takes no arguments just dumps all the sets we can find for the current database
version

=head2 make_schema

Given an existing database, reverse engineer a L<DBIx::Class> Schema in the
L</target_dir> (under C<dumped_db>).  You can use this if you need to bootstrap
your DBIC files.

=head2 populate

Given an array of fixture set names, populate the current database version with
the matching sets for that version.

Skips the table C<dbix_class_deploymenthandler_versions>, so you don't lose
deployment info (this is different from L</drop_tables> which does delete it.)

=head1 THANKS

Because of the awesomeness of CPAN and the work of many others, all this
functionality is provided with a few hundred lines of code.  In fact, I spent
a lot more time writing docs and tests than anything else. Here are  some
particular projects / people I'd like to thank:

First, thanks to C<mst> for providing me a big chunk of code that served to
kickstart my work, and served as an valuable prototype.

Thanks to C<frew> for the awesome L<DBIx::Class::DeploymentHandler> which gives
us such a powerful base for organizing database versions.  Thanks to all the
authors of L<DBIx::Class::Fixtures> for giving me a foundation for managing
sets of data.  Lastly, thanks to the L<DBIx::Class> cabal for all the work done
in making the L<DBIx::Class> ORM so amazingly powerful.

As usual, thanks to the L<Moose> cabal for making Perl programming fun and
beautiful.  Lastly, a shout-out to the L<Dist::Zilla> cabal for making it so I
don't need to write my own build and deployment tools.

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>

=head1 SEE ALSO

L<DBIx::Class::DeploymentHandler>, L<DBIx::Class::Fixtures>, L<DBIx::Class>,
L<DBIx::Class::Schema::Loader>, L<Moose>.

=head1 COPYRIGHT & LICENSE

Copyright 2012, John Napiorkowski L<email:jjnapiork@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

__END__

TODO

list-fixture-history
list-migration-history
delete fixture/migration version
list-fixture-sets
?? From version? ??
add ENV support for instantiation
Dzil and module install plugins
shell version
path DBIC-Fixtures to inflate-deflate
something to make testing easier
catalyst example

?? patch DH to abstract the filesysteem storage and get methods for 'last/next version'
?? patch DBIC-deploymenthander for autoversions

