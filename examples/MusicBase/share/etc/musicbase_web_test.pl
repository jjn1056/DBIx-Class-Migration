use DBIx::Class::Migration::Population;
use Test::DBIx::Class
  -schema_class=>'MusicBase::Schema',
  -traits=>['Testmysqld'],
  -replicants=>2;

{
  'Model::Schema' => {
    schema_class => 'MusicBase::Schema',
    connect_info => [
      sub {Schema()->storage->dbh},
      { on_connect_call => sub {
        DBIx::Class::Migration::Population->new(
          schema=>Schema())->populate('all_tables');
        } },
    ],
  },
};
