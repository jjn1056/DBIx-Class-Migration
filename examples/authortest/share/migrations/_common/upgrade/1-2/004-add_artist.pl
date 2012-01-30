sub {
  shift->resultset('Artist')
    ->create({
      name => 'JoJo',
      country_fk => {name=>'USA'},
      cds => [{title=>'My Cool New Album'}],
    });
}
