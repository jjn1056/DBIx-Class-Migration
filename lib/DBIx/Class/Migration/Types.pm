package DBIx::Class::Migration::Types;

use Type::Library
  -base,
  -declare => (
    'LoadableDBICSchemaClass',
    'SQLTProducer', 'ArraySQLTProducers',
    'AbsolutePath',
  );
use Type::Utils -all;
BEGIN { extends "Types::Standard" };

use Class::Load 'load_class';
use Module::Find ();
use File::Spec::Functions 'file_name_is_absolute', 'rel2abs';

declare LoadableClass,
  as Str,
  where { load_class $_ };

declare LoadableDBICSchemaClass,
  as LoadableClass,
  message { "$_ is not the name of a loadable schema class.  You probably have a typo, or some problem with \@INC"};

coerce LoadableDBICSchemaClass,
  from Str,
  via { to_LoadableClass($_); $_ };

my $sqltp = 'SQL::Translator::Producer';
declare SQLTProducer,
  as Str,
  where { eval { load_class "$sqltp\::$_"; 1 } },
  ;

declare ArraySQLTProducers,
  as ArrayRef[SQLTProducer],
  message {
    join '',
      "\nUnknown database type among (@$_) try:\n",
      map {s#$sqltp\::##; "$_\n"} Module::Find::findallmod($sqltp);
  },
  ;

declare AbsolutePath,
  as Str,
  where { file_name_is_absolute $_ },
  ;
coerce AbsolutePath,
  from Str,
  via { rel2abs $_ },
  ;

1;

=head1 NAME

DBIx::Class::Migration::Types - Custom Type::Tiny Types

=head1 SYNOPSIS

  use DBIx::Class::Migration::Types -all;
  use Moo;

  has 'schema' => isa=>LoadableClass;

=head1 DESCRIPTION

Custom L<Type::Tiny> types. Probably nothing here you need to worry about.

=head1 SEE ALSO

L<DBIx::Class::Migration>, L<Type::Tiny>

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut

