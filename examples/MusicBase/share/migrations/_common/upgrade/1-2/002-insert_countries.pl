
sub {
  shift->resultset('Country')
    ->populate([
      ['name'],
      ['Canada'],
      ['Mexico'],
      ['USA'],
  ]);
};
