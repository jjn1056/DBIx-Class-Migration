package DBIx::Class::Migration::SchemaLoader;

use Moose;

has schema => (is=>'ro', required=>1);

our $generated;
sub schema_from_database {
  my $schema = shift->schema->clone;
  $generated ||= DBIx::Class::Migration::SchemaLoader::_loader
    ->connect({
        dbh_maker => sub { $schema->storage->dbh },
    });
}

package ## Hide from PAUSE
  DBIx::Class::Migration::SchemaLoader::_loader;
 
use strict;
use warnings;
 
use base 'DBIx::Class::Schema::Loader';
 
__PACKAGE__->naming({ ALL => 'v7'});
__PACKAGE__->use_namespaces(1);
__PACKAGE__->loader_options( );

1;
