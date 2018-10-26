package Catalyst::Plugin::Statsd;

# ABSTRACT: log Catalyst stats to statsd

use v5.8;

use Moose::Role;

use POSIX qw/ ceil /;
use Ref::Util qw/ is_plain_arrayref /;

# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

requires 'finalize';

our $VERSION = 'v0.3.0';

=head1 SYNOPSIS

  use Catalyst qw/
     Statsd
     -Stats=1
   /;

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

=head1 METHODS

=head2 C<statsd_client>

  $c->statsd_client;

Returns the statsd client.

=cut

sub statsd_client {
    my ($c) = @_;
    return $c->req->env->{'psgix.monitor.statsd'};
}


=head2 C<statsd_metric_name_filter>

  $c->statsd_metric_name_filter( $stat_or_name );

This method returns the name to be used for logging stats, or C<undef>
if the metric should be ignored.

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

=head2 C<catalyst.stats.*.time>

These are metrics generated from L<Catalyst::Stats>.

=cut

sub statsd_metric_name_filter {
    my ($c, $stat) = @_;

    return "$stat" unless is_plain_arrayref($stat);

    my $metric = "catalyst.stats." . $stat->[1] . ".time";
    $metric =~ s/\W+/./g;

    return $metric;
}

around finalize => sub {
    my ( $next, $c ) = @_;

    if ( my $client = $c->statsd_client) {
        if ( $c->use_stats ) {

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

    }

    $c->$next;
};

=head1 KNOWN ISSUES

Enabling stats will also log a table of statistics to the Catalyst
log.  If you do not want this, then you will need to subclass
L<Catalyst::Stats> or modify your logger accordingly.

=head1 SEE ALSO

=over

=item *

L<Catalyst::Stats>

=item *

L<Plack::Middleware::Statsd>

=back

=head1 append:AUTHOR

The initial development of this module was sponsored by Science Photo
Library L<https://www.sciencephoto.com>.

=cut

1;
