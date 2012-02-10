sub {

  my $artist_rs = shift->resultset('Artist');

  $artist_rs->create({
    name =>'Michael Jackson',
    cds => [
      { title => 'Thriller', tracks => [
        { title => 'Beat It' },
        { title => 'Billie Jean' }],
      },
      { title => 'Bad', tracks => [
        { title => 'Dirty Diana' },
        { title => 'Smooth Criminal'},
        { title => 'Leave Me Alone' }],
      },
    ]
  });

  $artist_rs->create({
    name =>'Eminem',
    cds => [
      { title => 'The Marshall Mathers LP', tracks => [
        { title => 'Stan' },
        { title => 'The Way I Am' }],
      },
    ]});

};

