package Worker;
use strict;
use warnings;
use Clutch::Worker;

register_function(
    'echo' => sub {
        my $args = shift;
        $$ .':'. $args;
    }
);

1;

