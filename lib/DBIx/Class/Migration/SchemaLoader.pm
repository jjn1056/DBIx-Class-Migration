package  ## Hide from PAUSE
  DBIx::Class::Migration::SchemaLoader;

use Moose;
use DBIx::Class::Schema::Loader;

has schema => (is=>'ro', required=>1);

sub opts {
  naming => { ALL => 'v7'},
  use_namespaces => 1,
  debug => ($ENV{DBIC_MIGRATION_DEBUG}||0);
}

sub merge_opts { opts(), @_ };

sub _make_schema_at {
  my ($self, $name, %extra_opts) = @_;
  my $schema = $self->schema->clone;
  DBIx::Class::Schema::Loader::make_schema_at
    $name, {merge_opts(%extra_opts)}, [ sub {$schema->storage->dbh} ];
}

  my $_cnt = 0;
  sub next_cnt { $_cnt++ }
  sub _as_unique_ns { shift . next_cnt() }

sub schema_from_database {
  my ($self, $ns) = @_;
  $self->_make_schema_at(_as_unique_ns($ns));
}

sub generate_dump {
  my ($self, $ns, $dump_dir) = @_;
  $self->_make_schema_at(
    $ns,
    dump_directory => $dump_dir,
    exclude => qr/dbix_class_deploymenthandler_versions/,
  );
}

1;
