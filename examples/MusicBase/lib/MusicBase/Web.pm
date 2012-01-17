package MusicBase::Web;

use Moose;
use Catalyst qw/
  ConfigLoader
/;

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->config(
  'Plugin::ConfigLoader' => {
    file => __PACKAGE__->path_to('share', 'etc'),
  },
);

__PACKAGE__->setup;
__PACKAGE__->meta->make_immutable;
