package Local::Schema;
use base 'DBIx::Class::Schema';

our ($VERSION, $SUFFIX) = ($ENV{TUTORIAL_VERSION}||1, $ENV{TUTORIAL_SUFFIX}||1);

__PACKAGE__->load_namespaces(
  result_namespace => "+Local::SchemaV" .$SUFFIX. "::Result",
  resultset_namespace => "+Local::SchemaV" .$SUFFIX. "::ResultSet",
);

1;

