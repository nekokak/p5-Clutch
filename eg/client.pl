#! perl
use strict;
use warnings;
use Clutch::Client;

my $args = shift || die 'missing args';

my $client = Clutch::Client->new(
    servers => [
        +{ address => '127.0.0.1:5963' },
    ],
);
my $res = $client->request('echo', $args);

print $res, "\n";

