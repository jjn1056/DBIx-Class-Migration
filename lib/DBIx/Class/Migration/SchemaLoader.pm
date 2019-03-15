package  DBIx::Class::Migration::SchemaLoader;

use Moo;
use DBIx::Class::Schema::Loader;

has schema => (is=>'ro', required=>1);

sub opts {
  naming => { ALL => 'v7'},
  use_namespaces => 1,
  debug => ($ENV{DBIC_MIGRATION_DEBUG}||0);
}

sub _merge_opts { opts(), @_ };

sub _rearrange_connect_info {
   my ($storage) = @_;
   my $nci = $storage->_normalize_connect_info(
    $storage->connect_info);
   return (
    dbh_maker => sub { $storage->dbh },
    map %{$nci->{$_}}, grep { $_ ne 'arguments' } keys %$nci,
  );
}

sub _make_schema_at {
  my ($self, $name, %extra_opts) = @_;
  my $schema = $self->schema->clone;
  DBIx::Class::Schema::Loader::make_schema_at
    $name, {_merge_opts(%extra_opts)}, [{_rearrange_connect_info($schema->storage)}];
}

sub _next_cnt { our $_cnt++ }
sub _as_unique_ns { $_[0] . _next_cnt() }

sub schema_from_database {
  my ($self, $ns, %extra_opts) = @_;
  $self->_make_schema_at(_as_unique_ns($ns), %extra_opts);
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

=head1 NAME

DBIx::Class::Migration::SchemaLoader - Schema Loader Factory

=head1 SYNOPSIS

    For internal use only

=head1 DESCRIPTION

Often when running migrations we need to auto generate a L<DBIx::Class::Schema>
directly from the existing database.  This class performs that function.

There are no end user bits here, but we do expose an C<%ENV> variable which
turns on L<DBIx::Class::Schema::Loader> debugging mode.  This can be useful
since the generated schema will get dumped to STDOUT, helping you sort out
any confusion about your classes and relationships.

    export DBIC_MIGRATION_DEBUG=1

Or run it one time:

    DBIC_MIGRATION_DEBUG=1 dbic-migration [command]

=head1 SEE ALSO

L<DBIx::Class::Migration>, L<DBIx::Class::Schema::Loader>.

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut


