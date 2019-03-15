package DBIx::Class::Migration::SandboxDirSandboxBuilder;

use Moo;

has migration => (
  is => 'ro',
  weak_ref => 1,
  required => 1);

sub build {
  my $migration = shift->migration;
  return $migration->db_sandbox_class
    ->new(target_dir=>$migration->db_sandbox_dir,
     schema_class=>$migration->_infer_schema_class);
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

DBIx::Class::Migration::SandboxDirSandboxBuilder - Build a sandbox at db_sandbox_dir

=head1 SYNOPSIS

    use DBIx::Class::Migration::SandboxDirSandboxBuilder;

=head1 DESCRIPTION

Helper class that creates a C<db_sandbox> in the C<db_sandbox_dir>.

Useful when you want your sandbox in a different directory from the rest of your 
deployment and fixture files.

=head1 SEE ALSO

L<DBIx::Class::Migration>, L<DBIx::Class::Migration::Sandbox>.

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut


