package Worker;
use strict;
use warnings;
use Clutch::Worker;
use Data::Dumper;

register_function(
    'get_server_list' => sub {
        my $args = shift;
        warn Dumper $args;
        [qw/host1 host2 host3/];
    }
);

register_function(
    'get_server' => sub {
        my $args = shift;
        warn Dumper $args;
        # some process;
        +{os => 'debian'};
    }
);
1;

