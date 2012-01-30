## Add Belgium, Germany, France
#
sub {
  shift->resultset('Country')
    ->populate([
      ['code'],
      ['bel'],
      ['deu'],
      ['fra'],
  ]);
}
