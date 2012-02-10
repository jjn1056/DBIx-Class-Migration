package MusicBase::Schema::Result::Track;

use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('track');
__PACKAGE__->add_columns(
  'track_id' => {
    data_type => 'integer',
  },
  'cd_fk' => {
    data_type => 'integer',
  },
  'title' => {
    data_type => 'varchar',
    size => '96',
  });

__PACKAGE__->set_primary_key('track_id');
__PACKAGE__->belongs_to(
  'cd' => "MusicBase::Schema::Result::Cd",
  {'foreign.cd_id'=>'self.cd_fk'});

1;
