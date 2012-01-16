package MusicBase::Web::Model::Schema;

use Moose;
extends 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->meta->make_immutable;
