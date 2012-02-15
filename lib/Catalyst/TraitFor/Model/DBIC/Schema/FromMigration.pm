package Catalyst::TraitFor::Model::DBIC::Schema::FromMigration;

use Moose::Role;

has 'migration_helper',
  is => 'bare',
  handles => ['migration','do_install_if_needed'];

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $args = $class->$orig(@args);

  die "Can't use 'connect_info' with the 'FromMigration' trait."
    if $args->{connect_info};

  my %init_args = (
    schema_class => $args->{schema_class},
   ($args->{install_if_needed} ? (install_if_needed => delete $args->{install_if_needed}) : ()),
   ($args->{extra_migration_args} ? (extra_migration_args => delete $args->{extra_migration_args}) : ()));

  my $migration_helper = Catalyst::TraitFor::Model::DBIC::Schema::FromMigration::_MigrationHelper
    ->new(%init_args);

  $args->{migration_helper} = $migration_helper;
  $args->{connect_info} = sub {
    $migration_helper->migration->schema->storage->dbh;
  };

  return $args;
};

after BUILD => sub {
  my $self = shift;
  $self->do_install_if_needed;
};

package Catalyst::TraitFor::Model::DBIC::Schema::FromMigration::_MigrationHelper;

use Moose;
use DBIx::Class::Migration;

has 'schema_class',
  is => 'ro';

has 'extra_migration_args',
  is => 'ro',
  isa => 'HashRef',
  default => sub { +{} },
  auto_deref => 1;

has 'install_if_needed',
  is => 'ro',
  isa => 'HashRef|Bool',
  predicate => 'has_install_if_needed';

has 'migration',
  is => 'ro',
  lazy_build => 1;

sub _build_migration {
  my $self = shift;
  return DBIx::Class::Migration->new(
    schema_class => $self->schema_class,
    $self->extra_migration_args);
}

sub do_install_if_needed {
  my $self = shift;
  if($self->has_install_if_needed) {
    if(ref $self->install_if_needed) {
      $self->migration->install_if_needed(%{$self->install_if_needed})
    } else {
      $self->migration->install_if_needed;
    }
  }
}

1;

=head1 NAME



Catalyst::TraitFor::Model::DBIC::Schema::FromMigration - Use your DB Sandbox to run Catalyst

=head1 SYNOPSIS

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
          on_install => sub {
            my ($schema, $migration) = @_;
            $migration->populate('all_tables')}},
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

=head1 SEE ALSO

L<Catalyst::Model::DBIC::Schema>, L<Catalyst>

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information
use DBIx::Class::Migration::Script;
DBIx::Class::Migration::Script
  ->new_with_options->run;

=cut
