package App::Happyman::Plugin::SocketAnnouncer;
use Moose;

with 'App::Happyman::Plugin';

use AnyEvent::Handle;
use AnyEvent::Socket;

has '_announcer_socket_guard' => (
  is => 'ro',
  builder => '_build_announcer_socket_guard',
);

sub _build_announcer_socket_guard {
  my ($self) = @_;

  return tcp_server(undef, 6666, sub {
    my ($fh, $host, $port) = @_;
    my $handle;
    $handle = AnyEvent::Handle->new(
      fh       => $fh,
      on_eof   => sub { undef $handle },
      on_error => sub { undef $handle },
    );
    $handle->push_read(line => sub {
      my ($handle, $line, $eol) = @_;
      $self->_announce($host, $handle, $line);
    });
  });
}

sub _announce {
  my ($self, $host, $handle, $line) = @_;

  foreach my $channel (@{ $self->conn->channels }) {
    $self->conn->send_notice($channel, "$line [$host]");
  }

  my $w;
  $w = AE::timer(1, 0, sub {
    $handle->push_read(line => sub {
      my ($handle, $line, $eol) = @_;
      $self->_announce($host, $handle, $line);
      undef $w;
    });
  });
}

__PACKAGE__->meta->make_immutable();
