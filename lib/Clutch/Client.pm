package Clutch::Client;
use strict;
use warnings;
use Clutch::Util;
use Data::WeightedRoundRobin;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    %args = (
        servers       => undef,
        admin_address => undef,
        timeout       => 10,
        %args,
    );

    my $self = bless \%args, $class;

    if ($self->{admin_address}) {
        $self->_get_worker_list();
    }

    my @servers;
    for my $row (@{$self->{servers}}) {
        if (ref($row) eq 'HASH') {
            push @servers, +{ value => $row->{address}, weight => $row->{weight} };
        }
        else {
            push @servers, $row;
        }
    }
    $self->{dwr} = Data::WeightedRoundRobin->new(\@servers);

    $self;
}

sub _get_worker_list {
    my $self = shift;

    my $sock = Clutch::Util::new_client($self->{admin_address});

    my $msg = 'get_servers' . $CRLF x 2;
    Clutch::Util::write_all($sock, $msg, $self->{timeout}, $self);

    my $buf='';
    while (1) {
        my $rlen = Clutch::Util::read_timeout(
            $sock, \$buf, $MAX_REQUEST_SIZE - length($buf), length($buf), $self->{timeout}, $self
        ) or return;

        Clutch::Util::verify_buffer($buf) and do {
            Clutch::Util::trim_buffer(\$buf);
            last;
        }
    }
    $sock->close();

    my @servers;
    for my $line (split ',', $buf) {
        my ($address, $weight) = split '=', $line;
        push @servers, +{
            address => $address,
            weight  => $weight,
        };
    }
    $self->{servers} = \@servers;
}

sub request {
    my ($self, $function, $args) = @_;

    my $server = $self->{dwr}->next;
    my $sock = Clutch::Util::new_client($server);

    my $msg = join($CRLF, $function, $args) . $CRLF x 2;
    Clutch::Util::write_all($sock, $msg, $self->{timeout}, $self);

    my $buf='';
    while (1) {
        my $rlen = Clutch::Util::read_timeout(
            $sock, \$buf, $MAX_REQUEST_SIZE - length($buf), length($buf), $self->{timeout}, $self
        ) or return;

        Clutch::Util::verify_buffer($buf) and do {
            Clutch::Util::trim_buffer(\$buf);
            last;
        }
    }
    $sock->close();
    return $buf eq "\0" ? undef : $buf;
}

1;

