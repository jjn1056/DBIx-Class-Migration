package DBIx::Class::Migration::RunScript;

use Moose;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
  as_is => ['builder', 'migrate']);

with 'MooseX::Traits::Pluggable';

has '+_trait_namespace' => (default=>'+Trait');
has 'dbh' => (is=>'rw', isa=>'Object');
has 'version_set' => (is=>'rw', isa=>'ArrayRef');
has 'runs' => (
  is=>'ro',
  isa=>'CodeRef',
  required=>1);

sub run { shift->runs->(@_) }

sub as_coderef {
  my $self = shift;
  return sub {
    my ($schema, $version_set) = @_;
    $self->dbh($schema->storage->dbh);
    $self->version_set($version_set);
    $self->run;
  }
}

sub builder(&) {
  my ($runs, @plugins) = reverse shift->();
  my (@traits, %args);
  foreach my $plugins (@plugins) {
    if(ref $plugins) {
      %args = (%args, %$plugins);
    } else {
      push @traits, $plugins;
    }
  }

  return __PACKAGE__
    ->new_with_traits(traits=>\@traits, runs=>$runs, %args)
    ->as_coderef;
}

sub migrate(&) {
  my $runs = shift;
  builder { 'SchemaLoader', $runs };
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

DBIx::Class::Migration::RunScript - Control your Perl Migration Run Scripts

=head1 SYNOPSIS

Using the C<builder> exported subroutine:

    use DBIx::Class::Migration::RunScript;

    builder {
      'SchemaLoader',
      sub {
        shift->schema->resultset('Country')
          ->populate([
          ['code'],
          ['bel'],
          ['deu'],
          ['fra'],
        ]);
      };
    };

Alternatively, use the C<migrate> exported subroutine for normal defaults.

    use DBIx::Class::Migration::RunScript;

    migrate {
      shift->schema
        ->resultset('Country')
        ->populate([
          ['code'],
          ['bel'],
          ['deu'],
          ['fra'],
        ]);
    };

=head1 DESCRIPTION

When using Perl based run files for your migrations, this class lets you
manage that and offers a clean method to add in functionality.

See L<DBIx::Class::Migration::Tutorial> for an extended discussion.

=head1 ATTRIBUTES

This class defines the follow attributes

=head2 version_set

An arrayref of the from / to version you are attempting to migrate.

=head2 dbh

The current database handle to the database you are trying to migrate.

=head1 EXPORTS

This class defines the following exports

=head2 builder

Allows you to construct a migration script from a subroutine and also lets you
specify plugins.

=head2 migrate

Run a migration subref with default plugins.

=head1 SEE ALSO

L<DBIx::Class::Migration>.

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut



