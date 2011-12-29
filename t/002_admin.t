use strict;
use warnings;
use lib './t/lib';
use Test::More;
use Test::TCP;
use Clutch::Client;
use Clutch::Admin;
use IO::Socket;

sub _new_sock {
    my $port = shift;
    IO::Socket::INET->new(
        PeerAddr => '127.0.0.1:'.$port,
        Proto    => 'tcp',
    ) or die "Cannot open admin cient socket: $!";
}

test_tcp(
    client => sub {
        my ($port, $server_pid) = @_;


        {
            my $sock = _new_sock($port);
            $sock->print(join("\r\n", 'register', 'localhost:9999=100') . "\0");
            my $res = $sock->getline();
            note $res;
            is $res, 'OK';
        }

        {
            my $sock = _new_sock($port);
            $sock->print(join("\r\n", 'register', 'localhost:8888=') . "\0");
            my $res = $sock->getline();
            note $res;
            is $res, 'OK';
        }

        {
            my $sock = _new_sock($port);
            $sock->print("get_servers\0");
            my $res = $sock->getline();
            note $res;
            is $res, 'localhost:9999=100,localhost:8888=';
        }

        kill 'TERM', $server_pid;
    },
    server => sub {
        my $port = shift;
        Clutch::Admin->new(
            {
                address => '127.0.0.1:'.$port,
            }
        )->run();
    },
);

done_testing;

