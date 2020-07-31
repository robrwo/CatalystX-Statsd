# NAME

Catalyst::Plugin::Statsd - Log Catalyst stats to statsd

# VERSION

version v0.7.2

# SYNOPSIS

```perl
use Catalyst qw/
   Statsd
   -Stats=1
 /;

use Net::Statsd::Tiny;

__PACKAGE__->config(
  'psgi_middleware', [
      Statsd => {
          client => Net::Statsd::Tiny->new,
      },
  ],
);

# (or you can specify the Statsd middleware in your
# application's PSGI file.)
```

# DESCRIPTION

This plugin will log [Catalyst](https://metacpan.org/pod/Catalyst) timing statistics to statsd.

## CONFIGURATION

```perl
__PACKAGE__->config(

  'Plugin::Statsd' => {
      disable_stats_report => 0,
  },

);
```

## `disable_stats_report`

Enabling stats will also log a table of statistics to the Catalyst
log.  If you do not want this, then set `disable_stats_report`
to true.

Note that if you are modifying the `log_stats` method or using
another plugin that does this, then this may interfere with that if
you disable the stats report.

This defaults to

```
!$c->debug
```

# METHODS

## `statsd_client`

```
$c->statsd_client;
```

Returns the statsd client.

This is the statsd client used by [Plack::Middleware::Statsd](https://metacpan.org/pod/Plack::Middleware::Statsd).

## `statsd_metric_name_filter`

```
$c->statsd_metric_name_filter( $stat_or_name );
```

This method returns the name to be used for logging stats, or `undef`
if the metric should be ignored.

Only alphanumeric characters, hyphens or underscores in namespaces are
accepted. All other characters are converted to dots, with consecutive
dots compressed into a single dot.

If it is passed a non-arrayref, then it will stringify the argument
and return that.

If it is passed an array reference, then it assumes the argument comes
from [Catalyst::Stats](https://metacpan.org/pod/Catalyst::Stats) report and is converted into a suitable metric
name.

You can override or modify this method to filter out which metrics you
want logged, or to change the names of the metrics.

# METRICS

## `catalyst.response.time`

This logs the Catalyst reponse time that is normally reported by
Catalyst.  However, it is probably unnecessary since
[Plack::Middleware::Statsd](https://metacpan.org/pod/Plack::Middleware::Statsd) also logs response times.

## `catalyst.sessionid`

If [Catalyst::Plugin::Session](https://metacpan.org/pod/Catalyst::Plugin::Session) or [Plack::Middleware::Session](https://metacpan.org/pod/Plack::Middleware::Session) is
used, or anything that adds a `sessionid` method to the context, then
the session id is added as a set, to count the number of unique
sessions.

## `catalyst.stats.*.time`

These are metrics generated from [Catalyst::Stats](https://metacpan.org/pod/Catalyst::Stats).

All non-word characters in the paths in an action are changed to dots,
e.g. the timing for an action `/foo/bar` will be logged with the
metric `catalyst.stats.foo.bar.time`.

The metric name is generated by ["statsd\_metric\_name\_filter"](#statsd_metric_name_filter).

# KNOWN ISSUES

## Custom Profiling Points

If you have custom profiling points, then these will be treated as
top-level names in the `catalyst.stats.*` namespaces, e.g.

```perl
my $stats = $c->stats;
$stats->profile( begin => 'here' );

...

$stats->profile( end => 'here' );
```

will be logged to statsd in the `catalyst.stats.here.time` namespace.

If you do not want this, then you can work around this by prefixing
the block name with a controller name, e.g.

```perl
$stats->profile( begin => 'controller.here' );
```

## Large Databases When Profiling

When profiling your application, the size of your stats database may
grow quite large.

Your database storage and retention settings should be adjusted
accordingly.

# SEE ALSO

- [Catalyst::Stats](https://metacpan.org/pod/Catalyst::Stats)
- [Plack::Middleware::Statsd](https://metacpan.org/pod/Plack::Middleware::Statsd)
- [Net::Statsd::Tiny](https://metacpan.org/pod/Net::Statsd::Tiny)

# SOURCE

The development version is on github at [https://github.com/robrwo/CatalystX-Statsd](https://github.com/robrwo/CatalystX-Statsd)
and may be cloned from [git://github.com/robrwo/CatalystX-Statsd.git](git://github.com/robrwo/CatalystX-Statsd.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/CatalystX-Statsd/issues](https://github.com/robrwo/CatalystX-Statsd/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# CONTRIBUTOR

Slaven Rezić <slaven@rezic.de>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
