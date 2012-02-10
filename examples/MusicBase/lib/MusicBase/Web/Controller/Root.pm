package MusicBase::Web::Controller::Root;

use Moose;
use MooseX::MethodAttributes;

extends 'Catalyst::Controller';

sub index :Path :Args(0) {
  my ($self, $ctx) = @_;
  my @artists = $ctx->model('Schema::Artist')
    ->search({},{ result_class =>
      'DBIx::Class::ResultClass::HashRefInflator' })
    ->all;

  $ctx->stash(artists => \@artists);
}

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;

