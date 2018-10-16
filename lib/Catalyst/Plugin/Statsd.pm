package Catalyst::Plugin::Statsd;

use Moose::Role;

use POSIX qw/ ceil /;

# RECOMMEND PREREQ: Plack::Middleware::Statsd

use namespace::autoclean;

around finalize => sub {
    my ($next, $c) = @_;

    if ( my $client = $c->req->env->{'psgix.monitor.statsd'} )
{
        if ( $c->use_stats ) {

            my $elapsed = $c->stats->elapsed;

            $client->timing_ms( "catalyst.response.time",
                ceil( $elapsed * 1000 ) );

            foreach my $stat ($c->stats->report) {

                my $metric = "catalyst.stats." . $stat->[1] . ".time";
                my $timing = ceil( $stat->[2] * 1000 );

                $metric =~ s/\W+/./g;

                $client->timing_ms($metric, $timing);

            }

        }

    }

    $c->$next;
};

=head1 append:AUTHOR

The initial development of this module was sponsored by Science Photo
Library L<https://www.sciencephoto.com>.

=cut

1;
