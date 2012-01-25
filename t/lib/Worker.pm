package Worker;
use strict;
use warnings;
use Clutch::Worker;
use Test::More;

register_function(
    'function_name' => sub {
        my $args = shift;
        my $res = 'response='.$args;
        note $res;
        $res;
    }
);

register_function(
    'foo' => sub {
        my $args = shift;
        note 'execute';
        return;
    }
);

1;

