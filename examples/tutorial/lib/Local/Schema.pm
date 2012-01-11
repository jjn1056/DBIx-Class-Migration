package Local::Schema;
use base 'DBIx::Class::Schema';

our ($VERSION, $SUFFIX) = ($ENV{TUTORIAL_VERSION}||die("Missing Version"), 
  $ENV{TUTORIAL_SUFFIX}||die("Missing Suffix"));

__PACKAGE__->load_namespaces(
  result_namespace => "+Local::SchemaV" .$SUFFIX. "::Result",
  resultset_namespace => "+Local::SchemaV" .$SUFFIX. "::ResultSet",
);

1;

