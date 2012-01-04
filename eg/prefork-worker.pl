#! perl
use strict;
use warnings;
use lib './eg/lib';
use Worker;

Worker->new(
    {
        address     => '127.0.0.1:5963',
        max_workers => 5,
        max_reqs_per_child => 3,
    }
)->run();

