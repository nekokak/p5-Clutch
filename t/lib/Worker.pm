package Worker;
use strict;
use warnings;
use Clutch::Worker;

register_function(
    'function_name' => sub {
        my $args = shift;
        'response='.$args;
    }
);

register_function(
    'foo' => sub {
        my $args = shift;
        return;
    }
);

1;

