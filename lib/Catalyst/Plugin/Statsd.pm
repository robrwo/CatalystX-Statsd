package Catalyst::Plugin::Statsd;

# ABSTRACT: Log Catalyst stats to statsd

use v5.10.1;

use Moose::Role;

use POSIX qw/ ceil /;
use Ref::Util qw/ is_plain_arrayref /;

# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

requires qw/ log_stats /;

our $VERSION = 'v0.7.3';

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This plugin will log L<Catalyst> timing statistics to statsd.

=head2 CONFIGURATION

  __PACKAGE__->config(

    'Plugin::Statsd' => {
        disable_stats_report => 0,
    },

  );

=head2 C<disable_stats_report>

Enabling stats will also log a table of statistics to the Catalyst
log.  If you do not want this, then set C<disable_stats_report>
to true.

Note that if you are modifying the C<log_stats> method or using
another plugin that does this, then this may interfere with that if
you disable the stats report.

This defaults to

    !$c->debug

=head1 METHODS

=head2 C<statsd_client>

  $c->statsd_client;

Returns the statsd client.

This is the statsd client used by L<Plack::Middleware::Statsd>.

=cut

sub statsd_client {
    my ($c) = @_;
    return $c->req->env->{'psgix.monitor.statsd'};
}


=head2 C<statsd_metric_name_filter>

  $c->statsd_metric_name_filter( $stat_or_name );

This method returns the name to be used for logging stats, or C<undef>
if the metric should be ignored.

Only alphanumeric characters, hyphens or underscores in namespaces are
accepted. All other characters are converted to dots, with consecutive
dots compressed into a single dot.

If it is passed a non-arrayref, then it will stringify the argument
and return that.

If it is passed an array reference, then it assumes the argument comes
from L<Catalyst::Stats> report and is converted into a suitable metric
name.

You can override or modify this method to filter out which metrics you
want logged, or to change the names of the metrics.

=head1 METRICS

=head2 C<catalyst.response.time>

This logs the Catalyst reponse time that is normally reported by
Catalyst.  However, it is probably unnecessary since
L<Plack::Middleware::Statsd> also logs response times.

=head2 C<catalyst.sessionid>

If L<Catalyst::Plugin::Session> or L<Plack::Middleware::Session> is
used, or anything that adds a C<sessionid> method to the context, then
the session id is added as a set, to count the number of unique
sessions.

=head2 C<catalyst.stats.*.time>

These are metrics generated from L<Catalyst::Stats>.

All non-word characters in the paths in an action are changed to dots,
e.g. the timing for an action C</foo/bar> will be logged with the
metric C<catalyst.stats.foo.bar.time>.

The metric name is generated by L</statsd_metric_name_filter>.

=cut

sub statsd_metric_name_filter {
    my ($c, $stat) = @_;

    return "$stat" unless is_plain_arrayref($stat);

    my $metric = "catalyst.stats." . $stat->[1] . ".time";
    $metric =~ s/[^\w\-_]+/./g;

    return $metric;
}

around log_stats => sub {
    my ( $next, $c ) = @_;

    state $config = $c->config->{'Plugin::Statsd'} // {};

    if ( my $client = $c->statsd_client) {

        my $stat = [ -1, "catalyst.response.time", $c->stats->elapsed ];
        my $metric = $c->statsd_metric_name_filter($stat) or next;

        $client->timing_ms( "catalyst.response.time",
                            ceil( $stat->[2] * 1000 ) );

        foreach my $stat ( $c->stats->report ) {

            my $metric = $c->statsd_metric_name_filter($stat) or next;
            my $timing = ceil( $stat->[2] * 1000 );

            $client->timing_ms( $metric, $timing );

        }

    }

    my $disabled = $config->{disable_stats_report} // !$c->debug;

    $c->$next unless $disabled;
};

around finalize => sub {
    my ($next, $c) = @_;

    if (my $client = $c->statsd_client) {

        if ($c->can("sessionid") && (my $id = $c->sessionid)) {
            $client->set_add("catalyst.sessionid", "$id");
        }
        # Plack::Middleware::Session
        elsif (my $options = $c->req->env->{'psgix.session.options'}) {
            if (my $id = $options->{id}) {
                $client->set_add("catalyst.sessionid", "$id");
            }
        }
    }

    $c->$next();
};

=head1 KNOWN ISSUES

=head2 Custom Profiling Points

If you have custom profiling points, then these will be treated as
top-level names in the C<catalyst.stats.*> namespaces, e.g.

  my $stats = $c->stats;
  $stats->profile( begin => 'here' );

  ...

  $stats->profile( end => 'here' );

will be logged to statsd in the C<catalyst.stats.here.time> namespace.

If you do not want this, then you can work around this by prefixing
the block name with a controller name, e.g.

  $stats->profile( begin => 'controller.here' );

=head2 Large Databases When Profiling

When profiling your application, the size of your stats database may
grow quite large.

Your database storage and retention settings should be adjusted
accordingly.

=head1 SEE ALSO

=over

=item *

L<Catalyst::Stats>

=item *

L<Plack::Middleware::Statsd>

=item *

L<Net::Statsd::Tiny>

=back

=head1 append:AUTHOR

The initial development of this module was sponsored by Science Photo
Library L<https://www.sciencephoto.com>.

=cut

1;
