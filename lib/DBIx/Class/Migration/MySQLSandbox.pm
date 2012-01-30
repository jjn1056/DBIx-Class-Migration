package # Hide from PAUSE
  DBIx::Class::Migration::MySQLSandbox;

use Moose;
use Test::mysqld;
use File::Spec::Functions 'catdir', 'catfile';
use File::Path 'mkpath';

has target_dir => (is=>'ro', required=>1);
has schema_class => (is=>'ro', required=>1);
has test_mysqld => (is=>'ro', lazy_build=>1);

  sub _generate_sandbox_dir {
    my $schema_class = (my $self = shift)->schema_class;
    $schema_class =~ s/::/-/g;
    catdir($self->target_dir, lc($schema_class));
  }

sub _build_test_mysqld {
  my $base_dir = (my $self = shift)->_generate_sandbox_dir;
  my $auto_start = -d $base_dir ? 1:2;
  return Test::mysqld->new(
    auto_start => $auto_start,
    base_dir => $base_dir);
}

sub _write_start {
  my $base_dir = (my $self = shift)->test_mysqld->base_dir;
  mkpath(my $bin = catdir($base_dir, 'bin'));
  open( my $fh, '>', catfile($bin, 'start'))
    || die "Cannot open $bin/start: $!";

  my $mysqld = $self->test_mysqld->{mysqld};
  my $my_cnf = catfile($base_dir, 'etc', 'my.cnf');
  print $fh <<START;
#!/usr/bin/env sh

$mysqld --defaults-file=$my_cnf &
START

  close($fh);

  chmod oct("0755"), catfile($bin, 'start');
}

sub _write_stop {
  my $base_dir = (my $self = shift)->test_mysqld->base_dir;
  mkpath(my $bin = catdir($base_dir, 'bin'));
  open( my $fh, '>', catfile($bin, 'stop'))
    || die "Cannot open $bin/stop: $!";

  my $PIDFILE = $self->test_mysqld->{my_cnf}->{'pid-file'};
  print $fh <<STOP;
#!/usr/bin/env sh

kill \$(cat $PIDFILE)
STOP

  close($fh);

  chmod oct("0755"), catfile($bin, 'stop');
}

sub _write_use {
  my $base_dir = (my $self = shift)->test_mysqld->base_dir;
  mkpath(my $bin = catdir($base_dir, 'bin'));
  open( my $fh, '>', catfile($bin, 'use'))
    || die "Cannot open $bin/use: $!";

  my $SOCKET = $self->test_mysqld->{my_cnf}->{socket};
  my $mysqld = $self->test_mysqld->{mysqld};
  $mysqld =~s/d$//; ## ug. sorry :(

  print $fh <<USE;
#!/usr/bin/env sh

$mysqld --socket=$SOCKET -u root test
USE

  close($fh);

  chmod oct("0755"), catfile($bin, 'use');
}


sub make_sandbox {
  my $base_dir = (my $self = shift)->test_mysqld->base_dir;
  $self->_write_start;
  $self->_write_stop;
  $self->_write_use;

  return "DBI:mysql:test;mysql_socket=$base_dir/tmp/mysql.sock",'root','';
}

__PACKAGE__->meta->make_immutable;

