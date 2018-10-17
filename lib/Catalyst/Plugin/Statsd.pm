package Catalyst::Plugin::Statsd;

# ABSTRACT: log Catalyst stats to statsd

use v5.8;

use Moose::Role;

use POSIX qw/ ceil /;

use namespace::autoclean;

our $VERSION = 'v0.1.2';

around finalize => sub {
    my ( $next, $c ) = @_;

    if ( my $client = $c->req->env->{'psgix.monitor.statsd'} ) {
        if ( $c->use_stats ) {

            my $elapsed = $c->stats->elapsed;

            $client->timing_ms( "catalyst.response.time",
                ceil( $elapsed * 1000 ) );

            foreach my $stat ( $c->stats->report ) {

                my $metric = "catalyst.stats." . $stat->[1] . ".time";
                my $timing = ceil( $stat->[2] * 1000 );

                $metric =~ s/\W+/./g;

                $client->timing_ms( $metric, $timing );

            }

        }

    }

    $c->$next;
};

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
