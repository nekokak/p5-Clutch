#! perl
use strict;
use warnings;
use Clutch::Client;

my $args = shift || die 'missing args';

my $client = Clutch::Client->new(
    admin_address => '127.0.0.1:1919',
);
my $res = $client->request('echo', $args);

print $res, "\n";

