use Local::DemoV1;

sub {
  my $schema = shift;
  Local::DemoV1->install($schema);
};
