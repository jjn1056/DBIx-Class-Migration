package DBIx::Class::Migration::RunScript::Trait::Populate;

use Moo::Role;
use File::Spec::Functions 'catdir', 'catfile';
use JSON::MaybeXS;

requires 'schema';

sub populate {
  my ($self, @sets) = @_;

  my $fixtures_init_args =
    JSON::MaybeXS->new->decode( $ENV{DBIC_MIGRATION_FIXTURES_INIT_ARGS} );
  my $fixtures_obj =
    $ENV{DBIC_MIGRATION_FIXTURES_CLASS}->new($fixtures_init_args);

  foreach my $set(@sets) {
    $fixtures_obj->populate({
    no_deploy => 1,
    schema => $self->schema,
    directory => catdir($ENV{DBIC_MIGRATION_FIXTURE_DIR}, $set) });
  }
}

sub set_has_fixtures {
  my ($self, $set_to_check) = @_;
  return -d catdir($ENV{DBIC_MIGRATION_FIXTURE_DIR}, $set_to_check) ? 1:0;
}

1;

=head1 NAME

DBIx::Class::Migration::RunScript::Trait::Populate - Populate fixtures
=head1 SYNOPSIS

    use DBIx::Class::Migration::RunScript;

    builder {
      'SchemaLoader',
      'Populate',
      sub {
        shift->populate('countries');
      };
    };

=head1 DESCRIPTION

This is a L<Moo::Role> that adds a C<populate> method to your run script.
This allows you to access any of your previously dumped fixtures.  You might
find this useful when installing a database that was previously setup.

This trait requires a C<schema> previously defined, such as provided by 
L<DBIx::Class::Migration::RunScript::Trait::SchemaLoader>.

=head1 methods

This class defines the follow methods.

=head2 populate

Requires $arg || @args

Given a fixture set (or list of sets), use L<DBIx::Class::Fixtures> to populate
them to the current database.

When naming sets, you skip the '.json' extension.

=head2 set_has_fixtures

Requires $arg

Given a set name, returns a boolean about if that set actually has fixtures
previously dumped.

=head1 SEE ALSO

L<DBIx::Class::Migration>, L<DBIx::Class::Migration::RunScript>

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut


