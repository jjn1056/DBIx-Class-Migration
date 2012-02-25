package DBIx::Class::Migration::RunScript::Trait::DataDir;

use Moose::Role;
use Path::Class::Dir;

has 'data_dir' => (
  is=>'ro',
  lazy_build=>1);

sub _build_data_dir {
  my $self = shift;
}

1;

=head1 NAME

DBIx::Class::Migration::RunScript::Trait::DataDir - Access data in your Migration scripts

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

This class defines the following attributes.

=head2 data_dir

A L<Path::Class::Dir> object pointing to your migration data directory.

=head1 SEE ALSO

L<DBIx::Class::Migration>, L<DBIx::Class::Migration::RunScript>

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut



