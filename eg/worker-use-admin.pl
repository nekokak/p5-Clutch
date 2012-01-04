#! perl
use strict;
use warnings;
use lib './eg/lib';
use Worker;

Worker->new(
    {
        address => '127.0.0.1:5963',
        admin_address => '127.0.0.1:1919',
    }
)->run();

