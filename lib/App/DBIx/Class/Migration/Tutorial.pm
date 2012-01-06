package App::DBIx::Class::Migration::Tutorial;

1;

=head1 NAME

App::DBIx::Class::Migration - Tools to manage database Migrations

=head1 SYNOPSIS

This is a tutorial for the database migration and fixture generation tools
described at the usage / api level at L<App::DBIx::Class::Migration> and
L<dbic-migration>.  Although reviewing those docs would be helpful, I would
not consider it required for the tutorial.  However, I would expect you are
familiar with L<DBIx::Class> and that you are aware of the dependent projects
L<DBIx::Class::DeploymentHandler> and L<DBIx::Class::Fixtures>.  Having some
knowledge of L<SQLT> would also be valuable.

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
use cases and presents next steps.

All code mentioned in the tutorial can be found the C</tutorial> directory
contained in the distribution installation files.  Additionally, we will use
as a starting point a database as similar as possible to the one described
in L<DBIx::Class::Manual::Example> so that if you are still new to
L<DBIx::Class> you can review those docs and think of this tutorial as a
natural progression in learning.

=head1 DESCRIPTION

    TBD

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>

=head1 SEE ALSO

L<App::DBIx::Class::Migration>

=head1 COPYRIGHT & LICENSE

Copyright 2012, John Napiorkowski L<email:jjnapiork@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

