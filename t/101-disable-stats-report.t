#!perl

use Test::Most;

use lib 't/lib';

use Catalyst::Test 'StatsApp';

my $log    = StatsApp->log;
my $config = StatsApp->config;

$config->{'Plugin::Statsd'} = {
  disable_stats_report => 1,
};

my $res = request('/');

{
    no warnings 'once';

    cmp_deeply \@MockStatsd::Data,
      bag(
        re('^catalyst\.response\.time:\d+\|ms$'),
        re('^catalyst\.stats\.root\.base\.time:\d+\|ms$'),
      ),
      'expected metrics'
      or diag( explain \@MockStatsd::Data );

}

cmp_deeply $log->msgs,
  [
    {
        level   => 'debug',
        message => 'Statistics enabled',
        name    => ignore(),
    },
  ],
  'logged output (no stats report)';

done_testing;
