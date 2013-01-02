package Local::v2::Schema::Result::Country;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('country');
__PACKAGE__->add_columns(
  'country_id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'code' => {
    data_type => 'char',
    size => '3',
  },
);

__PACKAGE__->set_primary_key('country_id');
__PACKAGE__->add_unique_constraint(['code']);
__PACKAGE__->has_many(
  'artists' => "Local::v2::Schema::Result::Artist",
  {'foreign.country_fk'=>'self.country_id'});

1;
