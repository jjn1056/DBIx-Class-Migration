package DBIx::Class::Migration::Tutorial;

1;

=head1 NAME

DBIx::Class::Migration::Tutorial - How to use DBIx::Class::Migration

=head1 SYNOPSIS

This is a tutorial for the database migration and fixture generation tools
described at the usage / api level at L<DBIx::Class::Migration> and
L<DBIx::Class::Migration>.  Although reviewing those docs would be helpful, I would
not consider it required for the tutorial.  However, I would expect you are
familiar with L<DBIx::Class> and that you are aware of the dependent projects
L<DBIx::Class::DeploymentHandler> and L<DBIx::Class::Fixtures>.  Having some
knowledge of L<SQLT> would also be valuable.

I also assume you are familiar with the general problems of creating database
migrations, such as generating DDL diff files, etc.  This of course assumes you
have good working knowledge of DDL and SQL, as well as some general
understanding of database administration.

If you are new to L<DBIx::Class> I really recommend you perform that tutorial
first, and review its documentation.  

This tutorial identifies the problem we are trying to solve, walks though
increasingly complicated examples using these tools, and offers some advice
as to the limit of the tools values.  We will also give some examples of how
to make your migrations play well with common web application development
frameworks such as L<Catalyst> and how to use them with testing tools such
as L<Test::DBIx::Class>

By the completion of the tutorial I would expect you to understand how to
prepare and install migrations, create custom deployment steps (and modify
the stubs created during the prepare phase) as well as perform standard
development workflows for testing and roundtripping a database.

All code mentioned can be found the C</examples/tutorial> directory
contained in the distribution installation files.  Additionally, we will use
as a starting point a database as similar as possible to the one described
in L<DBIx::Class::Manual::Example> so that if you are still new to
L<DBIx::Class> you can review those docs and think of this tutorial as a
natural progression in learning.

=head1 INTRODUCTION

Dealing with change in your database can be a vexing problem.  You need the
ability manage database versions (how your database changes over time).  You
need to be able to upgrade seemlessly from one version to another.  You need
to be able to manage database and system data, and how they change over time.
Additionally you may need to be able to create subsets of data for testing,
and the ability to reset the databse to a given state at any time.

There's a lot of frameworks that claim to make this easy.  Generally this is
partially achieve by limiting the scope of changes allowed, and reducing your
ability to take maximum advantage of your database features.  I'm not going to
make that claim, because L<DBIx::Class> is an ORM that maximized your ability
to be flexible and model databases using best practices.  What I will try to
claim is that we can make solving the problem of database change possible,
standard, and managed.  This should reduce your stress, enable you to be more
productive and not fear the need to change your tables.

L<DBIx::Class::Migration> is build on top of L<DBIx::Class::DeploymentHander>,
which is a tool to create deployment files of full databases and database diffs
and also L<DBIx::Class::Fixtures>, which is a tool for serializing and
restoring sets of information.  You need to solve both problems in an
synchronized manner if you want to escape the fear of change.

=head1 DEFINITIONS

The following definitions are used to assist clarity of understand and are
in scope for the remainder of the tutorial

=head2 schema

An instance of a subclass of L<DBIx::Class::Schema>

=head2 database

a database such as SQLite or MySQL, that is running and available to accept
commands.

=head2 version

An integer which represents a snapshot of a schema or database that is frozen
for use.  Versions increment positively (1,2,...) and can differ between your
schema and your database.

=head2 fixture configuration

L<DBIx::Class::Fixtures> defined rule for serializing a subset of information
from a database.  Is linked to a version and produces L</fixtures>

=head2 fixtures

Subsets of information from your database, linked to a version, in the form of
individual files.

=head2 deployment

SQL and Perl files associated with a given version, or an upgrade or downgrade
between versions.

=head2 migration

fixture configurations, fixtures and deployment files for a given version, and
how to upgrade or downgrade to that version.

=head1 NEXT STEPS

Here's the next steps in the tutorial.  It goes without saying that you should
have a good working installation of Perl, and a dedicated L<local::lib>.  Please
see L<App::perlbrew> for help setting up such a perl installation.

I also assume you have SQLite installed and parts of the advanced tutorial will
assume you have MySQL availabe.  Please see L<MySQL::Sandbox> for some help in
getting a development instance of MySQL running.

=head2 STEP 1: Setup Project Files

L<DBIx::Class::Migration::Tutorial::Setup> shows you how to bootstrap a very
basic L<DBIx::Class> driven application.

=head2 STEP 2: First Migration, using dbic-migration and fixtures.

L<DBIx::Class::Migration::Tutorial::FirstMigration> takes the basic application
and prepare some migrations.

=head2 STEP 3: Creating upgrades and modify the database

L<DBIx::Class::Migration::Tutorial::SecondMigration> SHows you how to start
handling database change by creating a version 2 of the schema.  We also create
more complex fixtures and customize the migration.

=head1 SEE ALSO

L<App::DBIx::Class::Migration>, L<DBIx::Class::Manual::Example>

=head1 AUTHOR

See L<DBIx::Class::Migration> for author information

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::Migration> for copyright and license information

=cut

