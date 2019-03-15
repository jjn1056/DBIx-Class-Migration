package DBIx::Class::Migration::RunScript::Trait::SchemaLoader;

use Moo::Role;
use DBIx::Class::Schema::Loader;
use DBIx::Class::Migration::SchemaLoader;

requires 'dbh';

sub schema {
  my $dbh = (my $self = shift)->dbh;
  my $name = DBIx::Class::Migration::SchemaLoader::_as_unique_ns(
    'DBIx::Class::Migration::LoadedSchema');
  return DBIx::Class::Schema::Loader::make_schema_at(
    $name, {DBIx::Class::Migration::SchemaLoader::opts}, [ sub {$dbh} ]);
}

1;

=head1 NAME

DBIx::Class::Migration::RunScript::Trait::SchemaLoader - Give your Run Script a Schema

=head1 SYNOPSIS

    use DBIx::Class::Migration::RunScript;

    builder {
      'SchemaLoader',
      sub {
        shift->schema->resultset('Country')
          ->populate([
          ['code'],
          ['bel'],
          ['deu'],
          ['fra'],
        ]);
      };
    };

=head1 DESCRIPTION

This is a L<Moo::Role> that adds a C<schema> attribute to your 
L<DBIx::Class::Migration::RunScript>.  This C<schema> is generated via
L<DBIx::Class::Schema::Loader> so it is consistent to your actual deployed
database structure (it is not dependent on your actual code).

=head1 ATTRIBUTES

This class defines the follow attributes

=head2 schema

Using L<DBIx::Class::Schema::Loader> create a L<DBIx::Class::Schema> that
represents the connected database.

=head1 SEE ALSO

L<DBIx::Class::Migration>, L<DBIx::Class::Migration::RunScript>

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut


