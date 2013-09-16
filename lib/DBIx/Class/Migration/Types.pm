package DBIx::Class::Migration::Types;

use base 'MooseX::Types::Combine';

# tell perl this inline package has already been loaded
$INC{'DBIx/Class/Migration/_Types.pm'} = __FILE__;

__PACKAGE__->provide_types_from(
  'MooseX::Types::LoadableClass',
  'DBIx::Class::Migration::_Types');

package #hide from PAUSE
  DBIx::Class::Migration::_Types;

use MooseX::Types::LoadableClass 'LoadableClass';
use MooseX::Types::Moose 'Str', 'ClassName';
use MooseX::Types -declare => [ 'LoadableDBICSchemaClass' ];

subtype LoadableDBICSchemaClass,
  as LoadableClass,
  message { "$_ is not the name of a loadable schema class.  You probably have a typo, or some problem with \@INC"};

coerce LoadableDBICSchemaClass,
  from Str,
  via { to_LoadableClass($_); $_ };

1;

=head1 NAME

DBIx::Class::Migration::Types - Custom Moose Types

=head1 SYNOPSIS

  use DBIx::Class::Migration::Types 'Schema';
  use Moose;

  has 'schema' => isa=>Schema;

=head1 DESCRIPTION

Custom Types for Moose.  Probably nothing here you need to worry about.

=head1 SEE ALSO

L<DBIx::Class::Migration>, L<MooseX::Types>, L<MooseX::Types::LoadableClass>

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut

