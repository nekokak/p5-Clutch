package Clutch::Client;
use strict;
use warnings;
use Clutch::Util;
use Data::WeightedRoundRobin;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    %args = (
        servers => undef,
        timeout => 10,
        %args,
    );

    my $self = bless \%args, $class;

    my @servers;
    for my $row (@{$self->{servers}}) {
        if (ref($row) eq 'HASH') {
            push @servers, +{ value => $row->{address}, weight => $row->{weight} };
        }
        else {
            push @servers, $row;
        }
    }
    # FIXME: no use DWR
    $self->{dwr} = Data::WeightedRoundRobin->new(\@servers);

    $self;
}

sub request_background {
    my ($self, $function, $args) = @_;
    $self->_request('request_background', $function, $args);
}

sub request {
    my ($self, $function, $args) = @_;
    $self->_request('request', $function, $args);
}

sub _request {
    my ($self, $cmd_name, $function, $args) = @_;

    my $server = $self->{dwr}->next;
    my $sock = Clutch::Util::new_client($server);

    my $json_args = Clutch::Util::json->encode($args);
    my $msg = join($DELIMITER, $cmd_name, $function, $json_args) . $CRLF;
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
    return $buf eq $NULL ? undef : Clutch::Util::json->decode($buf);
}

1;

__END__

=head1 NAME

Clutch::Client - distributed job system's client class

=head1 SYNOPSIS

    # client script
    use strict;
    use warnings;
    use Clutch::Client;
    my $args = shift || die 'missing args';
    my $client = Clutch::Client->new(
        servers => [
            +{ address => "$worker_ip:$worker_port" },
        ],
    );
    my $res = $client->request('echo', $args);
    print $res, "\n";

=head1 METHOD

=head2 my $client = Clutch::Client->new(%opts);

=over

=item $opts{servers}

The value is a reference to an array of worker addresses.

If hash reference, the keys are address (scalar), weight (positive rational number)

The server address is in the form host:port for network TCP connections

Client will distribute Data::WeightedRoundRobin.

=item $opts{timeout}

seconds until timeout (default: 10)

=back

=head2 my $res = $client->request($function_name, $args);

=over

=item $function_name

worker process function name.

=item $args

get over client argument for worker process.

$args must be single line data.

=back

=head1 SEE ALSO

L<Data::WeightedRoundRobin>

=cut

