package Test::DBIx::Class::FixtureCommand::Population;

use Moo;
use DBIx::Class::Migration::Population;

with 'Test::DBIx::Class::Role::FixtureCommand';
 
sub install_fixtures {
  my ($self, $sets, @rest) = @_;
  my @sets = ref($sets) ? @$sets : ($sets, @rest);
  my $schema = $self
    ->schema_manager
    ->schema;

  DBIx::Class::Migration::Population
    ->new(schema=>$schema)
    ->populate(@sets);
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Test::DBIx::Class::FixtureCommand::Population - Use your fixtures in a test case.

=head1 SYNOPSIS

    use Test::Most;
    use Test::DBIx::Class
      -schema_class=>'MusicBase::Schema',
      -fixture_class => '::Population,
      qw(Artist);

    fixtures_ok ['all_tables'];
    fixtures_ok ['more_sets', 'and_even_more_sets'];

    ## You test cases ##

    done_testing;

=head1 DESCRIPTION

Integration between L<DBIx::Class::Migration::Population> and
L<Test::DBIx::Class>.  Does the L<Test::DBIx::Class::Role::FixtureCommand>
Role.

Allows you to pass an arrayref of fixture set names to C<fixtures_ok>.

=head1 SEE ALSO

L<DBIx::Class::Migration::Population>, L<Test::DBIx::Class>

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut
