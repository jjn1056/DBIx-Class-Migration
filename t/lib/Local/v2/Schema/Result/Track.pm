package Local::v2::Schema::Result::Track;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('track');
__PACKAGE__->add_columns(
  'track_id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'cd' => {
    data_type => 'integer',
  },
  'title' => {
    data_type => 'varchar',
    size => '96',
  });

__PACKAGE__->set_primary_key('track_id');
__PACKAGE__->belongs_to('cd' => 'Local::v2::Schema::Result::Cd');
 
1;
