package  ## Hide from PAUSE
  DBIx::Class::Migration::SchemaLoader;

use Moose;
use DBIx::Class::Schema::Loader;

has schema => (is=>'ro', required=>1);

my %opts = (
  naming => { ALL => 'v7'},
  use_namespaces => 1,
  debug => $ENV{DBIC_MIGRATION_DEBUG}||0);

my $cnt = 0;

sub schema_from_database {
  my $schema = shift->schema->clone;
  my $name = shift . $cnt++;
  DBIx::Class::Schema::Loader::make_schema_at
    $name, \%opts, [ sub {$schema->storage->dbh} ];
}

sub generate_dump {
  my ($self, $name, $dump_dir) = @_;
  my $schema = $self->schema->clone;
  my %local_opts = (
    %opts,
    dump_directory => $dump_dir,
    exclude => qr/dbix_class_deploymenthandler_versions/);

  DBIx::Class::Schema::Loader::make_schema_at
    $name, \%local_opts, [ sub {$schema->storage->dbh} ];
}

1;
