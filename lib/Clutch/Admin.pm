package Clutch::Admin;
use strict;
use warnings;
use Clutch::Worker;

my %WORKERS;
register_function(
    'register' => sub {
        my $args = shift;
        my ($address, $weight) = split '=', $args;
        push @{$WORKERS{common}}, [$address, $weight];
        return 'OK';
    }
);

register_function(
    'get_servers' => sub {
        my @servers;
        for my $row (@{$WORKERS{common}}) {
            push @servers, join('=',@$row);
        }
        return join ',', @servers;
    }
);

1;

