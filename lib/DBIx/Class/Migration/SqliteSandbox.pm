package DBIx::Class::Migration::SqliteSandbox;

use Moo;
use File::Spec::Functions 'catfile';

with 'DBIx::Class::Migration::Sandbox';

  sub _generate_filename_for_default_db {
    my ($schema_class) = @_;
    $schema_class =~ s/::/-/g;
    return lc($schema_class);
  }

  sub _generate_path_for_default_db {
    my ($schema_class, $target_dir) = @_;
    my $filename = _generate_filename_for_default_db($schema_class);
    return catfile($target_dir, "$filename.db");
  }

  sub _generate_sqlite_dsn {
    my $db_default_path = _generate_path_for_default_db(@_);
    return "DBI:SQLite:$db_default_path";
  }

sub make_sandbox {
  my ($self) = @_;
  return _generate_sqlite_dsn($self->schema_class, $self->target_dir), '', '' ;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

DBIx::Class::Migration::SqliteSandbox - Autocreate a Sqlite sandbox

=head1 SYNOPSIS

    use DBIx::Class::Migration;

    my $migration = DBIx::Class::Migration->new(
      schema_class=>'Local::Schema',
      db_sandbox_class=>'DBIx::Class::Migration::SqliteSandbox'),

    $migration->prepare;
    $migration->install;

Please note C<db_sandbox_class> is a lazy built attribute, and it will default
to L<DBIx::Class::Migration::SqliteSandbox>.

=head1 DESCRIPTION

In order to help you jumpstart your database design and deployment, by default
we will automatically create a sqlite based file database in your C<target-dir>.

This is the default supported option as documented in L<DBIx::Class::Migration>
and in L<DBIx::Class::Migration::Tutorial>.  L<DBD::SQLite> is useful for your
initial development and for when you are trying to build quick prototypes but
for production and more serious work I recommend you target a different 
database.  You can use L<MySQL::Sandbox> to make it easy to create local MySQL
sandboxes for development, including replication clusters.  For a more simple
(and limited) approach you can also use L<DBIx::Class::Migration::MySQLSandbox>
or L<DBIx::Class::Migration::PgSandbox>.

Nothing else is required to install in order to use this default option.

Since Sqlite is a simple, single file database that doesn't run persistently
we don't create any helper scripts.  If you want to access the database directly
you can do so with the C<sqlite3> commandline tool which you should get when
you get L<DBD::Sqlite>.  To access the sandbox database:

    sqlite3 [target_dir]/[schema_class].db

For example, if your C<schema_class> is C<MyApp::Schema> and your sandbox is in
the default C<share>:

    sqlite3  MyApp-Web/share/myapp-schema.db

You can also follow the tutorial L<DBIx::Class::Migration::Tutorial> since the
bulk of the tutorial uses the sqlite sandbox.

=head1 SEE ALSO

L<DBIx::Class::Migration>, L<DBD::Sqlite>.

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut

