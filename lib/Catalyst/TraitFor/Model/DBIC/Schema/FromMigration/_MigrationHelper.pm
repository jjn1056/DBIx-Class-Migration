package Catalyst::TraitFor::Model::DBIC::Schema::FromMigration::_MigrationHelper;

use Moo;
use DBIx::Class::Migration::Types -all;

has 'migration_class',
  is => 'ro',
  isa => LoadableClass,
  default => 'DBIx::Class::Migration',
  required => 1,
  ;

has 'schema_class',
  is => 'ro';

has 'migration_init_args',
  is => 'ro',
  isa => HashRef,
  default => sub { +{} },
  ;

has 'default_fixtures',
  is => 'ro',
  isa => ArrayRef,
  predicate => 'has_default_fixtures';

has 'install_if_needed',
  is => 'ro',
  isa => HashRef|Bool,
  predicate => 'has_install_if_needed';

has 'migration',
  is => 'lazy';

sub _build_migration {
  my $self = shift;
  my %init = %{ $self->migration_init_args };
  return $self->migration_class->new(%init);
}

sub _build_callback_from_default_fixtures {
  my @fixtures = @{ shift->default_fixtures };
  return sub {
    my ($schema, $migration) = @_;
    $migration->populate(@fixtures)};
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

Catalyst::TraitFor::Model::DBIC::Schema::FromMigration::_MigrationHelper - Trait Helper

=head1 SYNOPSIS

    use Catalyst::TraitFor::Model::DBIC::Schema::FromMigration::_MigrationHelper;
    
=head1 DESCRIPTION

This is a helper for L<Catalyst::TraitFor::Model::DBIC::Schema::FromMigration>.
There are no 'user servicable' parts here, this is a private class that exposes
a bit of L<DBIx::Class::Migration> to make hooking up an existing migration
database sandbox to L<Catalyst> easier and error free.

=head1 SEE ALSO

L<Catalyst::Model::DBIC::Schema>, L<Catalyst>, L<DBIx::Class::Migration>
L<Catalyst::TraitFor::Model::DBIC::Schema::FromMigration>

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

=cut
