#! perl
use strict;
use warnings;
use lib './eg/lib';
use Worker;

Worker->new(
    {
        address       => 'localhost:10000',
        admin_address => 'localhost:20000',
    }
)->run();

