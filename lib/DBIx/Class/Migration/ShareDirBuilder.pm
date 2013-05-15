package DBIx::Class::Migration::ShareDirBuilder;

use Moose;
use version 0.77;
use File::ShareDir::ProjectDistDir 0.3.1 ();

has schema_class => (
  is => 'ro',
  isa => 'Str',
  required => 1);

sub filename_from_class {
  (my $filename_part = shift) =~s/::/\//g;
  return $INC{$filename_part.".pm"};
}

sub class_to_distname {
  (my $dist = shift) =~s/::/-/g;
  return $dist;
}

sub build {
  my $class = shift->schema_class;
  File::ShareDir::ProjectDistDir->import('dist_dir',
    filename => filename_from_class($class));

  my $sharedir;
  while($class) {
    last if $sharedir = eval { dist_dir( class_to_distname($class) ) };
    last unless $class =~s/::[^\:\:]+$//;
  }

  return $sharedir || die "Can't find a share ($sharedir) for $class";

}

__PACKAGE__->meta->make_immutable;

=head1 NAME

DBIx::Class::Migration::ShareDirBuilder - Build a target_dir in /share

=head1 SYNOPSIS

    use DBIx::Class::Migration::ShareDirBuilder;

=head1 DESCRIPTION

This is a utility class that build the path to a distribution's C</share>
directory, whether the distribution is installed (via C<make install> or if
it is in development.

This probably isn't really user servicable, although if you need to make a
custom C<target_dir> builder, you could look at this for example.

=head1 SEE ALSO

L<DBIx::Class::Migration>.

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut

