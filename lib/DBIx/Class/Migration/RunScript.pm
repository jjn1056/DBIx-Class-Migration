package DBIx::Class::Migration::RunScript;

use Moo;
use Text::Brew qw(distance);
use Log::Any;
use Carp 'croak';
use DBIx::Class::Migration::Types -all;
use Exporter qw(import);

with 'MooX::Traits';

our @EXPORT = qw(builder migrate);

sub _log_die {
  my ($self, $msg) = @_;
  $self->log->error($msg);
  croak $msg;
}

has log => (
  is  => 'ro',
  isa => InstanceOf['Log::Any::Proxy'],
  default => sub { Log::Any->get_logger( category => 'DBIx::Class::Migration') },
);

sub _trait_namespace { 'DBIx::Class::Migration::RunScript::Trait' }

has 'dbh' => (is=>'rw', isa=>Object);
has 'version_set' => (is=>'rw', isa=>ArrayRef);
has 'runs' => (
  is=>'ro',
  isa=>CodeRef,
  required=>1);

sub run {
  my ($self) = @_;
  eval { $self->runs->(@_); 1 } ||
    $self->handle_errors($@);
}

sub handle_errors {
  my ($self, $err) = @_;
  if($err =~m/Can't find source for (.+?) at/) {
    my @presentsources = map {
      (distance($_, $1))[0] < 3 ? "$_ <== Possible Match\n" : "$_\n";
    } $self->schema->sources;

    $self->_log_die(<<"ERR");
$err
You are probably seeing this error because the DBIC source in your migration
script called "$1" doesn't match a source defined in the schema that
::SchemaLoader has inferred from your existing database.  You may be confused
since that source might exist in your hand coded Schema files.  Since your
migration script doesn't use your hand coded Schema (it can't since we cannot
be sure it is in sync with your database state) but instead uses SchemaLoader
to autogenerate a schema, it uses the default SchemaLoader rules for creating
source names from the database tables it finds.

To help you debug this issue, here's a list of the actual sources that the
schema available to your migration knows about:

 @presentsources
ERR
  } elsif($err =~m/No such column (.+?) on DBIx.+?Result::(.+?) at/) {
    my @presentsources = map {
      (distance($_, $1))[0] < 3 ? "$_ <== Possible Match\n" : "$_\n";
    } ($self->schema->resultset($2)->result_source->columns,
        $self->schema->resultset($2)->result_source->relationships);

    $self->_log_die(<<"ERR");
$err
You are probably seeing this error because the DBIC resultset $2 does
not have a column or method called $1 defined in the schema which
::SchemaLoader has inferred from your existing database.  You may be confused
since that method might exist in your hand coded Schema files.  Since your
migration script doesn't use your hand coded Schema (it can't since we cannot
be sure it is in sync with your database state) but instead uses SchemaLoader
to autogenerate a schema, it uses the default SchemaLoader rules for creating
column and method names.

To help you debug this issue, here's a list of the actual columns and methods
that $2 has available:

 @presentsources
ERR
  } else {
    $self->_log_die($err);
  }
}

sub as_coderef {
  my $self = shift;
  return sub {
    my ($schema, $version_set) = @_;
    $self->dbh($schema->storage->dbh);
    $self->version_set($version_set);
    $self->run;
  }
}

sub default_plugins {
  'SchemaLoader',
  'Populate',
  'Dump',
  'TargetPath',
}

sub used_plugins {
  #allow the user to specify plugins for the migration by just
  #use-ing them
  #We find them by looking for packages loaded in %INC that have
  #the key matching the namespace defined by $path
  my $path = 'DBIx/Class/Migration/RunScript/Trait/';
  my $match = "$path(.+).pm";

  #however, there's one danger: if there's already been a
  #migration object created, which will have MANY matches for
  #$path in it, along with __AND and other things that
  #Moox::Traits::Util names a package with dynamic roles, we
  #shouldn't try to include that. Packages made that way get the
  #same %INC value as MooX::Traits::Util, so let's save that.
  my $traits_path = $INC{'MooX/Traits/Util.pm'};

  #so we get the list of packages loaded that match $path
  my @traits = grep { m[$path]x } keys %INC;
  #filter out any that were made via MooX::Traits::Util, if it was
  #loaded at all, yet
  @traits = grep { $INC{$_} ne $traits_path } @traits if $traits_path;
  #and return the last part of the path, the name of the plugin
  return map { m[$match]x } @traits;
}

sub builder(&) {
  my ($runs, @plugins) = reverse shift->();
  my (@traits, %args, %seen);
  foreach my $plugins (@plugins) {
    if(ref $plugins) {
      %args = (%args, %$plugins);
    } elsif ($seen{$plugins}++) {
      # skip!
    } else {
      push @traits, $plugins;
    }
  }

  return __PACKAGE__
    ->new_with_traits(traits=>\@traits, runs=>$runs, %args)
    ->as_coderef;
}

sub migrate(&) {
  my $runs = shift;
  builder {
    default_plugins(),
    used_plugins(),
    $runs,
  };
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

DBIx::Class::Migration::RunScript - Control your Perl Migration Run Scripts

=head1 SYNOPSIS

Using the C<builder> exported subroutine:

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

Alternatively, use the C<migrate> exported subroutine for standard and external
plugins:

    use DBIx::Class::Migration::RunScript;
    use DBIx::Class::Migration::RunScript::Trait::AuthenPassphrase;

    migrate {
      shift->schema
        ->resultset('Country')
        ->populate([
          ['code'],
          ['bel'],
          ['deu'],
          ['fra'],
        ]);
    };

=head1 DESCRIPTION

When using Perl based run files for your migrations, this class lets you
manage that and offers a clean method to add in functionality.

See L<DBIx::Class::Migration::Tutorial> for an extended discussion.

=head1 ATTRIBUTES

This class defines the follow attributes

=head2 version_set

An arrayref of the from / to version you are attempting to migrate.

=head2 dbh

The current database handle to the database you are trying to migrate.

=head1 EXPORTS

This class defines the following exports

=head2 builder

Allows you to construct a migration script from a subroutine and also lets you
specify plugins.

=head2 migrate

Run a migration subref with default plugins (SchemaLoader, Populate, TargetDir
Dump) and any additional plugins that you've used.  For example:

    use DBIx::Class::Migration::RunScript;

    migrate {
      my $runscript = shift;
    }

In this case C<$runscript> is an instance of L<DBIx::Class::Migration::RunScript>
and has the default traits applied (see
L<DBIx::Class::Migration::RunScript::Trait::TargetPath>,
L<DBIx::Class::Migration::RunScript::Trait::Schema>,
L<DBIx::Class::Migration::RunScript::Trait::Populate>,
L<DBIx::Class::Migration::RunScript::Trait::Dump> for more).

Second example:

    use DBIx::Class::Migration::RunScript;
    use DBIx::Class::Migration::RunScript::Trait::AuthenPassphrase;

    migrate {
      my $runscript = shift;
    }

In this case C<$runscript> is an instance of L<DBIx::Class::Migration::RunScript>
with traits applied as above and in addition one more trait,
L<DBIx::Class::Migration::RunScript::Trait::AuthenPassphrase> which is available
on CPAN (is external because it carries a dependency weight I don't want to 
impose on people if they don't need it).

=head1 UTILITY SUBROUTINES

The follow subroutines are available as package method, and not exported

=head2 default_plugins

returns an array of the default plugins.

=head1 SEE ALSO

L<DBIx::Class::Migration>.

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut



