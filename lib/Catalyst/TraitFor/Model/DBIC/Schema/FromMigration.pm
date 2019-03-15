package Catalyst::TraitFor::Model::DBIC::Schema::FromMigration;

use Moo::Role;
use Catalyst::TraitFor::Model::DBIC::Schema::FromMigration::_MigrationHelper;

has 'migration_helper',
  is => 'bare',
  handles => ['migration','do_install_if_needed'];

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $args = $class->$orig(@args);

  my $connect_info = (delete $args->{connect_info}) || {};
  $args->{extra_migration_args}->{schema_class} = $args->{schema_class};

  my %init_args = (
   ($args->{migration_class} ? (migration_class => delete $args->{migration_class}) : ()),
   ($args->{default_fixtures} ? (default_fixtures => delete $args->{default_fixtures}) : ()),
   ($args->{install_if_needed} ? (install_if_needed => delete $args->{install_if_needed}) : ()),
   (migration_init_args => delete $args->{extra_migration_args}));

  my $migration_helper = Catalyst::TraitFor::Model::DBIC::Schema::FromMigration::_MigrationHelper
    ->new(%init_args);

  $args->{migration_helper} = $migration_helper;
  $args->{connect_info} = {
    dbh_maker => sub { $migration_helper->migration->schema->storage->dbh },
    ref $connect_info eq 'HASH' ? %$connect_info : @$connect_info,
  };

  return $args;
};

after BUILD => sub { shift->do_install_if_needed };

1;

=head1 NAME

Catalyst::TraitFor::Model::DBIC::Schema::FromMigration - Use your DB Sandbox to run Catalyst

=head1 SYNOPSIS

Use the trait in your L<Catalyst> configuration:

    'Model::Schema' => {
      traits => ['FromMigration'],
      schema_class => 'MusicBase::Schema',
      extra_migration_args => {
        db_sandbox_class => 'DBIx::Class::Migration::MySQLSandbox'},
      install_if_needed => {
        on_install => sub {
          my ($schema, $migration) = @_;
          $migration->populate('all_tables')}},
      },

=head1 DESCRIPTION

If you are in development and using a database sandbox auto created and
managed for you with L<DBIx::Class::Migration>, this is a trait to make
it easy to hook that sandbox up to your L<Catalyst> application.  The
following are roughly the same:

    package MusicBase::Web::Model::Schema;

    use Moose;
    extends 'Catalyst::Model::DBIC::Schema';

    __PACKAGE__->config
    (
        schema_class => 'MusicBase::Schema',
        connect_info => {
          dsn => 'DBI:SQLite:__path_to(share,musicbase-schema.db)__',
          user => '',
          password => '',
        },
    )

    __PACKAGE__->meta->make_immutable;

And using the trait:

    package MusicBase::Web::Model::Schema;

    use Moose;
    extends 'Catalyst::Model::DBIC::Schema';

    __PACKAGE__->config
    (
        traits => ['FromMigration'],
        schema_class => 'MusicBase::Schema',
        extra_migration_args => \%args,
        install_if_needed => {
          default_fixture_sets => ['all_tables']},
    )

    __PACKAGE__->meta->make_immutable;

The biggest reasons to use this trait would be it makes it harder to connect
the wrong database and it gives you some easy helpers for automatic database
installation and fixture population (as you can see in the above example).

=head1 CONFIG PARAMETERS

This trait uses the following configuration parameters:

=head2 extra_migration_args

Accepts: Hashref, Optional

A hashref of init arguments that you'd pass to the C<new> method of
L<DBIx::Class::Migration>.  C<schema_class> is inferred from the existing
config parameter, so you don't need to pass that one.  Other arguments of
use could be C<db_sandbox_class>.

    extra_migration_args => {
      db_sandbox_class => 'DBIx::Class::Migration::MySQLSandbox'},

For example would use a MySQL development sandbox instead of the default SQLite.

=head2 install_if_needed

Accepts Bool|HashRef, Optional

If this is a true value, run the L<DBIx::Class::Migration/install_if_needed>
method.  If the value is a Hashref, we will assume it is a hashref of callbacks
as documented, and use it as an argument (after de-reffing it).

=head1 METHODS

This role exposes the following public methods

=head2 migration

Returns the L<DBIx::Class::Migration> object created to assist setting up
and managing your database.

=head2 do_install_if_needed

Installs a database and possibly do some data population, if one does not yet
exist.

=head1 SEE ALSO

L<Catalyst::Model::DBIC::Schema>, L<Catalyst>

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut
