package # Hide from PAUSE
  DBIx::Class::Migration::SqliteSandbox;

use Moose;
use File::Spec::Functions 'catfile';

has target_dir => (is=>'ro', required=>1);
has schema_class => (is=>'ro', required=>1);

  sub _generate_filename_for_default_db {
    my ($schema_class) = @_;
    $schema_class =~ s/::/-/g;
    return lc($schema_class);
  }

  sub _generate_sqlite_dsn {
    my ($schema_class, $target_dir) = @_;
    my $filename = _generate_filename_for_default_db($schema_class);
    'DBI:SQLite:'. catfile($target_dir, "$filename.db");
  }

sub make_sandbox {
  my ($self) = @_;
  return _generate_sqlite_dsn($self->schema_class, $self->target_dir), '', '' ;
}

__PACKAGE__->meta->make_immutable;
