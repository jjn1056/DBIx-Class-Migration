sub {
  shift->resultset('Artist')
    ->create({
      name => 'JoJo',
      country_fk => {code=>'usa'},
      artist_cds => [
        { cd_fk => {
            title=>'My Cool New Album'}
        }
      ],
    });
}
