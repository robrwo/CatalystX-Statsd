package CatalystX::Statsd;

use Moose::Role;

use POSIX qw/ ceil /;

# RECOMMEND PREREQ: Plack::Middleware::Statsd

use namespace::autoclean;

around finalize => sub {
    my ($next, $c) = @_;

    if ( my $client = $c->req->env->{'psgix.monitor.statsd'} ) {

        if ( $c->use_stats ) {

            my $elapsed = $c->stats->elapsed;

            $client->timing( "catalyst.response.time",
                ceil( $elapsed * 1000 ) );

            my @report =
              map { [ $_->[1] =~ s/\W+/./gr, ceil( $_->[2] * 1000 ), ], }
              $c->stats->report;

            $client->timing( sprintf( 'catalyst.stats.%s.time', $_->[0] ),
                $_->[1] )
              for @report;

        }

    }

    $c->$next;
}

=head1 append:AUTHOR

The initial development of this module was sponsored by Science Photo
Library L<https://www.sciencephoto.com>.

=cut

1;
