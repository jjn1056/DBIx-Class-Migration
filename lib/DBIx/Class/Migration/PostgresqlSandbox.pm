package DBIx::Class::Migration::PostgresqlSandbox;

use Moo;
use Test::Postgresql58;
use File::Spec::Functions 'catdir', 'catfile';
use File::Path 'mkpath';
use POSIX qw(SIGINT);
use DBIx::Class::Migration::Types -all;

with 'DBIx::Class::Migration::Sandbox';

has test_postgresql => (is=>'lazy', isa=>Object);

  sub _generate_sandbox_dir {
    my $schema_class = (my $self = shift)->schema_class;
    $schema_class =~ s/::/-/g;
    catdir($self->target_dir, lc($schema_class));
  }

  sub _determine_auto_start {
    my $base_dir = shift;
    if(-d $base_dir) {
      if( -e catdir($base_dir, 'data','postmaster.pid')) {
        return 0;
      } else {
        return 1;
      }
    } else {
      return 2;
    }
  }

sub _build_test_postgresql {
  my $base_dir = (my $self = shift)->_generate_sandbox_dir;
  my $auto_start = _determine_auto_start($base_dir);
  my %config = (
    auto_start => $auto_start,
    base_dir => $base_dir,
    initdb_args => $Test::Postgresql58::Defaults{initdb_args},
    postmaster_args => $Test::Postgresql58::Defaults{postmaster_args});

  unless($auto_start) {
    open ( my $pid_fh, '<', catdir($base_dir, 'data','postmaster.pid')) ||
      $self->log_die( "Can't open PID file" );
    my @lines = <$pid_fh>;
    close ($pid_fh);
    $config{port} = $lines[3];
  }

  if(my $testdb = Test::Postgresql58->new(%config)) {
    return $testdb;
  } else {
    $self->log_die( $Test::Postgresql58::errstr );
  }
}

sub _write_start {
  my $base_dir = (my $self = shift)->test_postgresql->base_dir;
  mkpath(my $bin = catdir($base_dir, 'bin'));
  open( my $fh, '>', catfile($bin, 'start'))
    || $self->log_die( "Cannot open $bin/start: $!" );

  my $test_postgresql = $self->test_postgresql;
  my $postmaster = $test_postgresql->{postmaster};
  my $data = catdir($base_dir, 'data');
  my $port = $test_postgresql->{port};

  print $fh <<START;
#!/usr/bin/env sh

$postmaster -p $port -D $data &
START

  close($fh);

  chmod oct("0755"), catfile($bin, 'start');
}

sub _write_stop {
  my $base_dir = (my $self = shift)->test_postgresql->base_dir;
  mkpath(my $bin = catdir($base_dir, 'bin'));
  open( my $fh, '>', catfile($bin, 'stop'))
    || $self->log_die( "Cannot open $bin/stop: $!" );

  my $test_postgresql = $self->test_postgresql;
  my $postmaster = $test_postgresql->{postmaster};
  my $pid = catdir($base_dir, 'data','postmaster.pid');

  print $fh <<STOP;
#!/usr/bin/env sh

kill -INT `head -1 $pid`
STOP

  close($fh);

  chmod oct("0755"), catfile($bin, 'stop');
}

sub _write_use {
  my $base_dir = (my $self = shift)->test_postgresql->base_dir;
  mkpath(my $bin = catdir($base_dir, 'bin'));
  open( my $fh, '>', catfile($bin, 'use'))
    || $self->log_die( "Cannot open $bin/use: $!" );

  my $test_postgresql = $self->test_postgresql;
  my $postmaster = $test_postgresql->{postmaster};
  my $psql = $postmaster;
  $psql =~s/postmaster$/psql/; # ugg
  my $port = $test_postgresql->{port};

  print $fh <<USE;
#!/usr/bin/env sh

$psql -h localhost --user postgres --port $port -d template1
USE

  close($fh);

  chmod oct("0755"), catfile($bin, 'use');
}

sub _write_dump {
  my $base_dir = (my $self = shift)->test_postgresql->base_dir;
  mkpath(my $bin = catdir($base_dir, 'bin'));
  open( my $fh, '>', catfile($bin, 'dump'))
    || $self->log_die( "Cannot open $bin/dump: $!" );

  my $test_postgresql = $self->test_postgresql;
  my $postmaster = $test_postgresql->{postmaster};
  my $psql = $postmaster;
  $psql =~s/postmaster$/pg_dump/; # ugg
  my $port = $test_postgresql->{port};

  print $fh <<USE;
#!/usr/bin/env sh

$psql -h localhost --user postgres --port $port \$@
USE

  close($fh);

  chmod oct("0755"), catfile($bin, 'dump');
}

sub _write_config {
  my $base_dir = (my $self = shift)->test_postgresql->base_dir;
  mkpath(my $bin = catdir($base_dir, 'bin'));
  open( my $fh, '>', catfile($bin, 'config'))
    || $self->log_die( "Cannot open $bin/config $!" );

  my $test_postgresql = $self->test_postgresql;
  my $postmaster = $test_postgresql->{postmaster};
  my $psql = $postmaster;
  $psql =~s/postmaster$/pg_dump/; # ugg
  my $port = $test_postgresql->{port};

  print $fh <<USE;
#!/usr/bin/env perl

my \$connect_info => { dsn => 'DBI:Pg:dbname=template1;host=localhost;port=$port', user => 'postgres', password => '' }

USE

  close($fh);

  chmod oct("0755"), catfile($bin, 'config');
}


sub make_sandbox {
  my $self = shift;
  my $base_dir = $self->_generate_sandbox_dir;

  if($self->test_postgresql) {
    $self->_write_start;
    $self->_write_stop;
    $self->_write_use;
    $self->_write_dump;
    $self->_write_config;

    my $port = $self->test_postgresql->port;
    return "DBI:Pg:dbname=template1;host=127.0.0.1;port=$port",'postgres','';
  } else {
    $self->log_die( "can't start a postgresql sandbox" );
  }
}

## I have to stop the database manually, not sure why, something borks 
## postgresql when SQLT->translate in DBIC-DH is called.

#sub DEMOLISH { shift->test_postgresql->stop(SIGINT) }

# ^ 03/04/2015 commenting this out since I 'think' its not an issue anymore

__PACKAGE__->meta->make_immutable;

=head1 NAME

DBIx::Class::Migration::PostgresqlSandbox - Autocreate a postgresql sandbox

=head1 SYNOPSIS

    use DBIx::Class::Migration;

    my $migration = DBIx::Class::Migration->new(
      schema_class=>'Local::Schema',
      db_sandbox_class=>'DBIx::Class::Migration::PostgresqlSandbox'),

    $migration->prepare;
    $migration->install;

=head1 DESCRIPTION

This automatically creates a postgresql sandbox in your C<target_dir> that you can
use for initial prototyping, development and demonstration.  If you want to
use this, you will need to add L<Test::Postgresql58> to your C<Makefile.PL> or your
C<dist.ini> file, and get that installed properly.  It also requires that you
have Postgresql installed locally (although Postgresql does not need to be running, as
long as we can find in $PATH the binary installation).  If your copy of Postgresql
is not installed in a normal location, you might need to locally alter $PATH
so that we can find it. For example, on my Mac, the path to Postgresql binaries
are at C</Library/PostgreSQL/bin> so you can alter the PATH for a single command
like so:

    PATH=Library/PostgreSQL/bin:$PATH [command]

Or, if you are using Postgresql a lot, you can edit your C<.bashrc> to make the
above permanent.

NOTE: You might find installing L<DBD::Pg> to be easier if you edit the
C<$PATH> before trying to install it.

In addition to the Postgresql sandbox, we create several helper scripts C<start>,
C<stop> and C<use> which can be used to start, stop and open shell level access
to you mysql sandbox.  C<dump> lets you easily access pg_dump and C<config> is
a Perl library that returns a hashref of the connection info, which is suitable
to use in L<DBIx::Class> Schema connect.

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
            config
            dump
            start
            stop
            use

This give you a system for installing a sandbox locally for development,
starting and stopping it for use (for example in a web application like one you
might create with L<Catalyst>) and for using it by opening a native C<psql>
shell (such as if you wish to review the database manually, and run native SQL
queries).

=head1 SEE ALSO

L<DBIx::Class::Migration>, L<DBD::Pg>, L<Test::Postgresql58>.

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut


