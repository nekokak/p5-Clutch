#! perl
use strict;
use warnings;
use lib './eg/lib';
use Worker;

Worker->new(
    {
        address => 'localhost:10000',
    }
)->run();

