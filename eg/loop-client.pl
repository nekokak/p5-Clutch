#! perl
use strict;
use warnings;
use Clutch::Client;
use Time::HiRes qw(sleep);

my $args = shift || die 'missing args';

my $client = Clutch::Client->new(
    servers => [
        +{ address => '127.0.0.1:5963' },
    ],
);

while (1) {
    my $res = $client->request('echo', $args);
    print $res, "\n";
    sleep 0.5;
}


