package DBIx::Class::Migration::RunScript;

use Moose;
use Moose::Exporter;
use overload '&{}' => sub {
  my ($self, $schema) = @_;
  shift->to_app(@_) };

Moose::Exporter->setup_import_methods(
  as_is => ['builder']);

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
      ->(@_);
  }
}

__PACKAGE__->meta->make_immutable;

