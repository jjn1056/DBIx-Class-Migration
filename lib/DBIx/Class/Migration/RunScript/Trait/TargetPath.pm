package DBIx::Class::Migration::RunScript::Trait::TargetPath;

use Moo::Role;
use File::Spec;

sub target_path {
  my ($self, @paths) = @_;
  return File::Spec->catdir($ENV{DBIC_MIGRATION_FIXTURE_DIR}, @paths);
}

1;

=head1 NAME

DBIx::Class::Migration::RunScript::Trait::TargetPath - Your migration target directory

=head1 SYNOPSIS

    use DBIx::Class::Migration::RunScript;

    builder {
      'TargetPath',
      sub {
        open(my $file, '<', shift->target_path('file'));
      };
    };

=head1 DESCRIPTION

Sometimes you would like to access your migration target directory when running
migration scripts.  For example, you might have some data stored in CSV files
and you want to load that data into the database as part of your migration.

=head1 methods

This class defines the follow methods.

=head2 target_path

@args are optional.

returns a path to whatever C<target_dir> is (typically PROJECT_ROOT/share if
you are using the default).  If you pass @args, those args will be added as
path parts to the returned path.

Example usage:

  $self->target_path
  $self->target_path('file');
  $self->target_path('path', 'to', 'file');

=head1 SEE ALSO

L<DBIx::Class::Migration>, L<DBIx::Class::Migration::RunScript>

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut


