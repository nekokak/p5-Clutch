#! perl
use strict;
use warnings;
use Clutch::Admin;

my $admin = Clutch::Admin->new(+{admin_address => 'localhost:20000'});
$admin->run();

