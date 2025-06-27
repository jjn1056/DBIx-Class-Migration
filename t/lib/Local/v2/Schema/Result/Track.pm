package Local::v2::Schema::Result::Track;
use base qw/DBIx::Class::Core/;

use utf8;
use strict;
use warnings;

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


sub sqlt_deploy_hook {
  my( $self, $sqlt_table ) =  @_;

  $sqlt_table->schema->add_procedure(
    name => 'test_utf',
    parameters => [ name => '_string', type => 'text' ],
    extra => {
      returns => { type => 'VOID' },
      definitions => [
        { language => 'sql' },
        { quote    => '$$', body => 'SELECT "перевірка ЮТФ/check UTF"' },
      ]
    }
  );

  $sqlt_table->schema->add_trigger(
    name =>  'test_utf',
    perform_action_when =>  'before',
    database_events     =>  'update',
    on_table            =>  $sqlt_table->name,
    scope               =>  'row',
    action              =>  q!EXECUTE PROCEDURE test_utf("перевірка ЮТФ/check UTF")!
  );

}

1;
