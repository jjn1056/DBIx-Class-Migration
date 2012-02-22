package DBIx::Class::Migration::RunScript;

use Moose;
use Moose::Exporter;
use overload '&{}' => sub {
  shift->to_app(@_) };

Moose::Exporter->setup_import_methods(
  as_is => ['builder', 'migrate']);

with 'MooseX::Traits::Pluggable';

has '+_trait_namespace' => (default=>'+Trait');
has 'dbh' => (is=>'rw');
has 'runs' => (
  is=>'ro',
  isa=>'CodeRef',
  required=>1);

sub call { shift->runs->(@_) }

sub to_app {
  my $self = shift;
  return sub {
    $self->dbh(shift->storage->dbh);
    $self->call;
  }
}

sub builder(&) {
  my @steps = shift->();
  my $runs = pop @steps;

  my (@traits, %args);
  foreach my $step (@steps) {
    if(ref $step) {
      %args = (%args, %$step);
    } else {
      push @traits, $step;
    }
  }

  return sub {
    DBIx::Class::Migration::RunScript
      ->new_with_traits(traits=>\@traits, runs=>$runs, %args)
      ->to_app->(@_);
  }
}

sub migrate(&) {
  DBIx::Class::Migration::RunScript
    ->new_with_traits(traits=>['SchemaLoader'], runs=>shift)
    ->to_app;
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

For now see L<DBIx::Class::Migration::Tutorial> regarding this functionality.

=head1 SEE ALSO

L<DBIx::Class::Migration>.

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut



