package DBIx::Class::Migration::SchemaLoader;
 
use strict;
use warnings;
 
use base 'DBIx::Class::Schema::Loader';
 
__PACKAGE__->naming({ ALL => 'v7'});
__PACKAGE__->use_namespaces(1);
__PACKAGE__->loader_options( );

sub load_and_connect_from {
  my ($class, $schema) = @_;
  $class->connect(sub { $schema->storage->dbh });
}

1;

