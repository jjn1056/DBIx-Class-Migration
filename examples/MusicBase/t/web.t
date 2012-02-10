#!/usr/bin/env perl

use Test::Most;
use Catalyst::Test 'MusicBase::Web';

ok my $content  = get('/'),
  'got some content';

like $content, qr/Michael Jackson/,
  'Found Michael Jackson';

done_testing;

