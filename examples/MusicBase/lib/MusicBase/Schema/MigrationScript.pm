package MusicBase::Schema::MigrationScript;

use Moose;
use MusicBase::Web;

extends 'DBIx::Class::Migration::Script';

sub defaults {
  schema => MusicBase::Web->model('Schema')->schema,
}

__PACKAGE__->meta->make_immutable;
__PACKAGE__->run_if_script;
