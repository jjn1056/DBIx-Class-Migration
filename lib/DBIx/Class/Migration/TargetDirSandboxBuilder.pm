package DBIx::Class::Migration::TargetDirSandboxBuilder;

use Moo;

has migration => (
  is => 'ro',
  weak_ref => 1,
  required => 1);

sub build {
  my $migration = shift->migration;
  return $migration->db_sandbox_class
    ->new(target_dir=>$migration->target_dir,
     schema_class=>$migration->_infer_schema_class);
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

DBIx::Class::Migration::TargetDirSandboxBuilder - Build a sandbox at target_dir

=head1 SYNOPSIS

    use DBIx::Class::Migration::TargetDirSandboxBuilder;

=head1 DESCRIPTION

Helper class that creates a C<db_sandbox> in the C<target_dir>.

=head1 SEE ALSO

L<DBIx::Class::Migration>, L<DBIx::Class::Migration::Sandbox>.

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut


