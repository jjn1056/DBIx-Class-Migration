package DBIx::Class::Migration::TempDirBuilder;

use Moo;
use File::Temp 'tempdir';
use DBIx::Class::Migration::Types -all;

has schema_class => (
  is => 'ro',
  isa => Str,
  required => 1);

sub build { tempdir( CLEANUP=>1 ) }

__PACKAGE__->meta->make_immutable;

=head1 NAME

DBIx::Class::Migration::TempDirBuilder - Build a tempory target_dir 

=head1 SYNOPSIS

    use DBIx::Class::Migration::TempDirBuilder;

=head1 DESCRIPTION

This creates your migration files in a temporary directory.  This might
be useful to you for testing.  Please understand that the lifespan of your
temporary directory will expire when your migration object goes out of
scope.

This probably isn't really user servicable, although if you need to make a
custom C<target_dir> builder, you could look at this for example.

=head1 SEE ALSO

L<DBIx::Class::Migration>, L<File::Temp>.

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut

