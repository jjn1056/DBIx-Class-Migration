package DBIx::Class::Migration::MySQLSandbox;

use Moo;
use Test::mysqld;
use File::Spec::Functions 'catdir', 'catfile', 'splitpath';
use File::Path 'mkpath';
use File::Temp 'tempdir';
use Config::MySQL::Reader;

with 'DBIx::Class::Migration::Sandbox';

has test_mysqld => (is=>'lazy');

  sub _generate_schema_path_part {
    my $schema_class = (my $self = shift)->schema_class;
    $schema_class =~ s/::/-/g;
    return lc $schema_class;
  }

  sub _generate_sandbox_dir {
    my $self = shift;
    return catdir($self->target_dir, $self->_generate_schema_path_part);
  }

  sub _generate_unique_socket {
    my $schema_path_part = (my $self = shift)->_generate_schema_path_part;
    my $sockdir = catdir( tempdir(CLEANUP => 1), $schema_path_part);

    mkpath($sockdir) unless -d $sockdir;
    return  catfile( $sockdir, 'mysqld.sock');
  }

sub _build_test_mysqld {
  my $base_dir = (my $self = shift)->_generate_sandbox_dir;
  my $auto_start = 2;
  my $my_cnf = {
   'skip-networking' => '',
    socket => $self->_generate_unique_socket };

  if( -d $base_dir) {
    $auto_start = 1;
    my $conf = Config::MySQL::Reader->read_file( catfile($base_dir, 'etc', 'my.cnf') ) ||
      $self->log_die( "Can't read my.cnf file" );
    $my_cnf = { socket => $conf->{mysqld}->{socket} };
    if( -e $conf->{mysqld}->{socket}) {
      $auto_start = 0;
    } else {
      my ($volume, $directory, $file) =
        splitpath($conf->{mysqld}->{socket});
      mkpath $directory;
    }
  }

  return Test::mysqld->new(
    auto_start => $auto_start,
    base_dir => $base_dir,
    my_cnf => $my_cnf );
}

sub _write_start {
  my $base_dir = (my $self = shift)->test_mysqld->base_dir;
  mkpath(my $bin = catdir($base_dir, 'bin'));
  open( my $fh, '>', catfile($bin, 'start'))
    || $self->log_die( "Cannot open $bin/start: $!" );

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
    || $self->log_die( "Cannot open $bin/stop: $!" );

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
    || $self->log_die( "Cannot open $bin/use: $!" );

  my $mysqld = $self->test_mysqld->{mysqld};
  my $SOCKET = $self->test_mysqld->my_cnf->{socket};
  $mysqld =~s/d$//; ## ug. sorry :(

  print $fh <<USE;
#!/usr/bin/env sh

$mysqld --socket=$SOCKET -u root test
USE

  close($fh);

  chmod oct("0755"), catfile($bin, 'use');
}

sub make_sandbox {
  my $self = shift;
  my $base_dir = $self->_generate_sandbox_dir;

  if( -e catfile($base_dir, 'tmp', 'mysqld.pid')) {
    return $self->test_mysqld->dsn;
  } elsif($self->test_mysqld) {
    $self->_write_start;
    $self->_write_stop;
    $self->_write_use;
    return $self->test_mysqld->dsn;
  } else {
    $self->log_die( "can't start a mysql sandbox" );
  }
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

DBIx::Class::Migration::MySQLSandbox - Autocreate a mysql sandbox

=head1 SYNOPSIS

    use DBIx::Class::Migration;

    my $migration = DBIx::Class::Migration->new(
      schema_class=>'Local::Schema',
      db_sandbox_class=>'DBIx::Class::Migration::MySQLSandbox'),

    $migration->prepare;
    $migration->install;

=head1 DESCRIPTION

This automatically creates a mysql sandbox in your C<target_dir> that you can
use for initial prototyping, development and demonstration.  If you want to
use this, you will need to add L<Test::mysqld> to your C<Makefile.PL> or your
C<dist.ini> file, and get that installed properly.  It also requires that you
have MySQL installed locally (although MySQL does not need to be running, as
long as we can find in $PATH the binary installation).  If your copy of MySQL
is not installed in a normal location, you might need to locally alter $PATH
so that we can find it.

For example, on my Mac, C<mysqld> is located at C</usr/local/mysql/bin/mysqld>
so I could do something like this:

    PATH=/usr/local/mysqlbin:$PATH [command]

and alter the C<$PATH> for one time running, or I could change the C<$PATH> 
permanently by editing my C<.bashrc> file (typically located in C<$HOME>).

NOTE: You might find installing L<DBD::mysql> to be easier if you edit the
C<$PATH> before trying to install it.

In addition to the MySQL sandbox, we create three helper scripts C<start>,
C<stop> and C<use> which can be used to start, stop and open shell level access
to you mysql sandbox.

These helper scripts will be located in a child directory of your C<target_dir>
(which defaults to C<share> under your project root directory).  For example:

    [target_dir]/[schema_class]/bin/[start|stop|use]

If your schema class is C<MyApp::Schema> you should see helper scripts like

    /MyApp-Web
      /lib
        /MyApp
          Schema.pm
          /Schema
            ...
      /share
        /migrations
        /fixtures
        /myapp-schema
          /bin
            start
            stop
            use

This give you a system for installing a sandbox locally for development,
starting and stopping it for use (for example in a web application like one you
might create with L<Catalyst>) and for using it by opening a native C<mysql>
shell (such as if you wish to review the database manually, and run native SQL
queries).

=head1 SEE ALSO

L<DBIx::Class::Migration>, L<DBD::mysql>, L<Test::mysqld>.

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut

