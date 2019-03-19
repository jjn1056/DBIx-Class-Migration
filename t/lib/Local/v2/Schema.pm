package Local::v2::Schema;
use base 'DBIx::Class::Schema';

require version;
our $VERSION = version->declare(2);

__PACKAGE__->load_namespaces;

1;

