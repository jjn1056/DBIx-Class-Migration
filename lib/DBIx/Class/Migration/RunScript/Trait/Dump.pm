package DBIx::Class::Migration::RunScript::Trait::Dump;

use Moo::Role;
use File::Spec::Functions 'catdir', 'catfile';
use File::Path 'mkpath';
use JSON::MaybeXS;

requires 'schema';

sub dump {
  my ($self, @sets) = @_;

  my $fixtures_init_args =
    JSON::MaybeXS->new->decode( $ENV{DBIC_MIGRATION_FIXTURES_INIT_ARGS} );
  my $fixtures_obj =
    $ENV{DBIC_MIGRATION_FIXTURES_CLASS}->new($fixtures_init_args);

  $fixtures_obj->dump_config_sets({
    schema => $self->schema,
    configs => [map { "$_.json" } @sets],
    directory_template => sub {
      my ($fixture, $params, $set) = @_;
      $set =~s/\.json//;
      my $fixture_conf_dir = catdir($ENV{DBIC_MIGRATION_FIXTURE_DIR}, $set);
      mkpath($fixture_conf_dir)
        unless -d $fixture_conf_dir;
      return $fixture_conf_dir;
    },
  });
}

1;

=head1 NAME

DBIx::Class::Migration::RunScript::Trait::Dump - Dump fixtures

=head1 SYNOPSIS

    use DBIx::Class::Migration::RunScript;

    builder {
      'SchemaLoader',
      'Dump',
      sub {
        shift->dump('countries');
      };
    };

=head1 DESCRIPTION

This is a L<Moo::Role> that adds a C<dump> method to your run script.  This
will let you dump fixtures from your runscripts, based on previously defined
fixture configurations.

This might be useful to you if you are building fixtures if they don't already
exist (see L<DBIx::Class::Migration::RunScript::Trait::Populate>) and then want
to dump them as part of building up your database.  For example:

    use DBIx::Class::Migration::RunScript;

    migrate {
      my $self = shift;
      if($self->set_has_fixtures('all_tables')) {
        $self->populate('all_tables');
      } else {
        $self->schema
          ->resultset('Country')
          ->populate([
            ['code'],
            ['bel'],
            ['deu'],
            ['fra'],
          ]);

        $self->dump('all_tables');
      }
    };

In the above example if the fixture set exists and has previously been dumped
we will populate the database with it.  Else, we will create some data manually
and then dump it so that next time it is available.

This trait requires a C<schema> previously defined, such as provided by
L<DBIx::Class::Migration::RunScript::Trait::SchemaLoader>.

This trait is one of the defaults for the exported method C<migrate> in
L<DBIx::Class::Migration::RunScript>.

=head1 methods

This class defines the follow methods.

=head2 dump

Requires $arg || @args

Given a fixture set (or list of sets), use L<DBIx::Class::Fixtures> to dump
them from the current database.

When naming sets, you skip the '.json' extension.

=head1 SEE ALSO

L<DBIx::Class::Migration>, L<DBIx::Class::Migration::RunScript>

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut


