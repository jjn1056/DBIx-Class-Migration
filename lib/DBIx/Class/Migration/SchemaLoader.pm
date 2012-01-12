package  ## Hide from PAUSE
  DBIx::Class::Migration::SchemaLoader;

use Moose;
use DBIx::Class::Schema::Loader;

has schema => (is=>'ro', required=>1);

sub schema_from_database {
  my ($self, $loader) = @_;
  my $schema = shift->schema->clone;
  ($loader || 'DBIx::Class::Migration::SchemaLoader::_loader')
    ->connect({
        dbh_maker => sub { $schema->storage->dbh },
    });
}

sub generate_dump {
  my ($self, $dump_dir) = @_;
  my $schema = shift->schema->clone;

  DBIx::Class::Schema::Loader::make_schema_at(
    'Local::Schema', 
    {
      naming => { ALL => 'v7'},
      use_namespaces => 1,
      exclude => qr/dbix_class_deploymenthandler_versions/,
      dump_directory => $dump_dir,
      debug => $ENV{DBIC_MIGRATION_DEBUG}||0,
    },
    [ sub {$schema->storage->dbh} ]);
}

package ## Hide from PAUSE
  DBIx::Class::Migration::SchemaLoader::_loader;
 
use strict;
use warnings;
 
use base 'DBIx::Class::Schema::Loader';
 
__PACKAGE__->naming({ ALL => 'v7'});
__PACKAGE__->use_namespaces(1);

1;
