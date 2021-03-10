use lib '.';
use t::Helper;
plan skip_all => 'TEST_ONLINE=1'   unless $ENV{TEST_ONLINE} or -e '.test-everything';
plan skip_all => 'cpanm CSS::Sass' unless eval 'use CSS::Sass 3.3.0;1';

my ($t, @message);
my $url = 'https://raw.githubusercontent.com/select2/select2/master/src/scss/core.scss';

run();
ok + (grep {/Caching/} @message), 'cached assets' or diag join ',', @message;
ok + (grep {/Unable to download.*_layout\.scss/} @message), 'unable to download' or map { diag $_ } @message;

run();
ok !(grep {/Caching/} @message),                           'assets are already cached'     or diag join ',', @message;
ok !(grep {/Unable to download.*_layout\.scss/} @message), 'assets are already downloaded' or diag join ',', @message;

done_testing;

sub run {
  @message = ();
  $t       = t::Helper->t(pipes => ['Sass']);
  $t->app->log->on(message => sub { shift; push @message, join ' ', @_ });
  $t->app->asset->process('app.css' => $url);
  $t->get_ok('/')->status_is(200);
  $t->get_ok($t->tx->res->dom->at('link[href]')->{href} || '/nope')->status_is(200)->content_like(qr{select2});
}

__DATA__
@@ index.html.ep
%= asset 'app.css'
