package DBIx::Class::Migration::Sandbox;

use Moo::Role;
use Log::Any;
use Carp 'croak';
use DBIx::Class::Migration::Types -all;

has target_dir => (is=>'ro', required=>1);
has schema_class => (is=>'ro', required=>1);

sub log_die {
  my ($self, $msg) = @_;
  $self->log->error($msg);
  croak $msg;
}

has log => (
    is  => 'ro',
    isa => InstanceOf['Log::Any::Proxy'],
    default => sub { Log::Any->get_logger( category => 'DBIx::Class::Migration') },
);

requires 'make_sandbox';

1;

=head1 NAME

DBIx::Class::Migration::Sandbox - DB Sandbox Role

=head1 SYNOPSIS

    package MyApp::Schema::Sandbox;

    use Moo;
    with 'DBIx::Class::Migration::Sandbox';

    sub make_sandbox {
      my ($self) = @_;

      ## Custom Processing to establish a running database

      return $dsn, $user, $password;
    }

    __PACKAGE__->meta->make_immutable;


=head1 DESCRIPTION

L<DBIx::Class::Migration> lets you easily create user level sandboxes of
your databases, which are suitable for prototyping and development.  It comes
with support for creating MySQL, Sqlite and Postgresql sandboxes.  However you
might have custom sandboxing needs.  In which you can create a class that does
this role.

The one required method C<make_sandbox>, should return something we can pass
to L<DBIx::Class::Schema/connect>.

=head1 SEE ALSO

L<DBIx::Class::Migration>, L<DBIx::Class::Migration::SqliteSandbox>,
L<DBIx::Class::Migration::MySQLSandbox>,
L<DBIx::Class::Migration::PostgresqlSandbox>

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut


