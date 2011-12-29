#! perl
use strict;
use warnings;
use Clutch::Client;
use Data::Dumper;

my $client = Clutch::Client->new(
    servers => [
        'localhost:10000',
    ],
);
my $res;

$res = $client->request('get_server_list', +{foo => 'bar'});
warn Dumper $res;

$res = $client->request('get_server', +{foo => 'bar'});
warn Dumper $res;

$res = $client->request('hoge', +{foo => 'bar'});
warn Dumper $res;
