package Clutch::Util;
use strict;
use warnings;
use parent qw(Exporter);
use IO::Socket::INET;
use POSIX qw(EINTR EAGAIN EWOULDBLOCK);
use Socket qw(IPPROTO_TCP TCP_NODELAY);

our $CRLF  = "\x0d\x0a";
our $SPACE = "\x20";
our $NULL  = "\x00";
our $MAX_REQUEST_SIZE = 131072;

our @EXPORT = qw($CRLF $SPACE $NULL $MAX_REQUEST_SIZE);

our %CMD2NO = (
    'request'            => 1,
    'request_background' => 2,
);
my %NO2CMD = reverse %CMD2NO;

sub new_client {
    my $address = shift;

    my $sock = IO::Socket::INET->new(
        PeerAddr => $address,
        Proto    => 'tcp',
    ) or die "Cannot open client socket: $!";

    setsockopt($sock, IPPROTO_TCP, TCP_NODELAY, pack("l", 1)) or die;
    $sock->autoflush(1);
    $sock;
}

sub cmd_to_no {
    my $name = shift;
    return $CMD2NO{$name} or die "unknown Clutch command name: $name";
}

sub no_to_cmd {
    my $no = shift;
    return $NO2CMD{$no} or die "unknown Clutch command no: $no";
}

# double line break indicates end of header; parse it
sub verify_buffer {
    my $buf = shift;
    # FIXME /o
    $buf =~ /^(.*?$CRLF)/s ? 1 : 0;
}

sub trim_buffer {
    my $buf = shift;
    # FIXME /o
    $$buf =~ s/$CRLF$//;
}

sub parse_read_buffer {
    my ($buf, $ret) = @_;

    if ( verify_buffer($buf) ) {
        trim_buffer(\$buf);
        ($ret->{cmd_no}, $ret->{function}, $ret->{args}) = split $SPACE, $buf;
        $ret->{args} ||= '';
        return 1;
    }

    return 0;
}

# returns (positive) number of bytes read, or undef if the socket is to be closed
sub read_timeout {
    my ($sock, $buf, $len, $off, $timeout, $self) = @_;
    do_io(undef, $sock, $buf, $len, $off, $timeout, $self);
}

# returns (positive) number of bytes written, or undef if the socket is to be closed
sub write_timeout {
    my ($sock, $buf, $len, $off, $timeout, $self) = @_;
    do_io(1, $sock, $buf, $len, $off, $timeout, $self);
}

# writes all data in buf and returns number of bytes written or undef if failed
sub write_all {
    my ($sock, $buf, $timeout, $self) = @_;
    my $off = 0;
    while (my $len = length($buf) - $off) {
        my $ret = write_timeout($sock, $buf, $len, $off, $timeout, $self)
            or return;
        $off += $ret;
    }
    return length $buf;
}

# returns value returned by $cb, or undef on timeout or network error
sub do_io {
    my ($is_write, $sock, $buf, $len, $off, $timeout, $self) = @_;
    my $ret;
    unless ($is_write || delete $self->{_is_deferred_accept}) {
        goto DO_SELECT;
    }
 DO_READWRITE:
    # try to do the IO
    if ($is_write) {
        $ret = syswrite $sock, $buf, $len, $off
            and return $ret;
    } else {
        $ret = sysread $sock, $$buf, $len, $off
            and return $ret;
    }
    unless ((! defined($ret)
                 && ($! == EINTR || $! == EAGAIN || $! == EWOULDBLOCK))) {
        return;
    }
    # wait for data
 DO_SELECT:
    while (1) {
        my ($rfd, $wfd);
        my $efd = '';
        vec($efd, fileno($sock), 1) = 1;
        if ($is_write) {
            ($rfd, $wfd) = ('', $efd);
        } else {
            ($rfd, $wfd) = ($efd, '');
        }
        my $start_at = time;
        my $nfound = select($rfd, $wfd, $efd, $timeout);
        $timeout -= (time - $start_at);
        last if $nfound;
        return if $timeout <= 0;
    }
    goto DO_READWRITE;
}

1;

