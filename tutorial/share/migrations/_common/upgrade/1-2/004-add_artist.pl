sub {
  shift->resultset('Artist')
    ->create({
      name => 'JoJo',
      countryfk => {name=>'USA'},
      cds => [{title=>'My Cool New Album'}],
    });
}
