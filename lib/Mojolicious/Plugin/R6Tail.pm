package Mojolicious::Plugin::R6Tail;

use strict;
use warnings;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw/slurp/;
use Carp ();
use Encode ();

use constant DEFAULT_TAIL_OPTIONS => '-f -n +0';

has 'template' => <<'TEMPLATE';
<html><head>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <title><%= $file %> - Webtail</title>
  %= stylesheet begin
  /* Stolen from https://github.com/r7kamura/webtail */
  *  {
    margin: 0;
    padding: 0;
  }
  body {
    margin: 1em 0;
    color: #ddd;
    background: #111;
  }
  #message {
    position:fixed;
    top:1em;
    right:1em;
  }
  #log {
    width: 80%;
    margin: 10px auto;
  }

  #log .l {
    display: block;
    font-style: normal;
    line-height: 1.25;
    font-family: "Monaco", "Consolas", monospace;
    white-space: pre-wrap;
  }

  #log .s_STDOUT { color: white; }
  #log .s_STDERR { color: yellow; }
  #log .s_MSGOUT {
    font-weight: bold;
    color: white;
    background: blue;
  }
  #log .s_MSGERR {
    font-weight: bold;
    color: white;
    background: red;
  }

  % end
  %= javascript 'https://ajax.googleapis.com/ajax/libs/jquery/1.7/jquery.min.js'
  %= javascript begin
  $(function() {
    var autoscroll = true;
    var ws = new (WebSocket || MozWebSocket)('<%= $ws_url %>');
    var timer_id;
    ws.onopen = function() {
      console.log('Connection opened');
      timer_id = setInterval(
        function() {
          console.log('Connection keepalive');
          ws.send('keepalive');
        },
        1000 * 240
      );
    };
    ws.onmessage = function(msg) {
        //if (msg.data == '\n' && $('pre:last').text() == '\n') return;

        var data = msg.data.split("\n");
        for (var i = 0, l = data.length; i < l; i++) {
            if (i == l-1 && !data[i].length ) { continue }
            var stream = data[i].substr(0, 6);
            var line   = data[i].substr(8);
            $('<i class="l s_' + stream + '">')
                .text(line).appendTo($('#log'));
        }

        if (autoscroll) $('html, body').scrollTop($(document).height());
    };
    ws.onclose = function() {
      console.warn('Connection closed');
      clearInterval(timer_id);
    };
    ws.onerror = function(msg) {
      console.error(msg.data);
    };


    $(window).keydown(function(e) {
        // press 's' key to toggle autoscroll
        if (e.keyCode == 83 ) autoscroll = (autoscroll) ? false : true;
        // press 'e' key to close socket
        //if (e.keyCode == 69 ) {
          //  console.log('Closing socket');
            //ws.close();
        //}
    });
  });
  % end
</head><body>
<div id="message">press 's' to toggle autoscroll</div>
<div id="log"></div>
</body></html>
TEMPLATE

has 'file';
has 'webtailrc';
has 'tail_opts' => sub { DEFAULT_TAIL_OPTIONS };

has '_tail_seen' => '';
has '_tail_stream';
has '_clients' => sub { +{} };

sub DESTROY {
    my $self = shift;
    $self->_tail_stream->close if $self->_tail_stream;
}

sub _prepare_stream {
    my ( $self, $app ) = @_;

    return if ( $self->_tail_stream );

    my ( $fh, $pid );
    my $read_from = 'STDIN';
    if ( $self->file ) {
        require Text::ParseWords;
        my @opts = Text::ParseWords::shellwords( $self->tail_opts );
        my @cmd  = ('tail', @opts, $self->file);
        $pid = open( $fh, '-|', @cmd ) or Carp::croak "fork failed: $!";
        $read_from = join ' ', @cmd;
    }
    else {
        $fh = *STDIN;
    }
    $app->log->debug("reading from: $read_from");

    my $stream    = Mojo::IOLoop::Stream->new($fh)->timeout(0);
    my $stream_id = Mojo::IOLoop->stream($stream);
    $stream->on( read => sub {
        my ($stream, $chunk) = @_;
        $chunk = Encode::decode_utf8( $chunk );
        $self->_tail_seen($self->_tail_seen . $chunk);
        for my $key (keys %{ $self->_clients }) {
            my $tx = $self->_clients->{$key};
            next unless $tx->is_websocket;
            $tx->send($chunk);
            # $app->log->debug( sprintf('sent %s', $key ) );
        }
    } );
    $stream->on( error => sub {
        $app->log->error( sprintf('error %s', $_[1] ) );
        Mojo::IOLoop->remove($stream_id);
        $self->_tail_seen('');
        $self->_tail_stream(undef);
    });
    $stream->on( close => sub {
        $app->log->debug('close tail stream');
        if ($pid) {
            kill 'TERM', $pid if ( kill 0, $pid );
            waitpid( $pid, 0 );
        };
        Mojo::IOLoop->remove($stream_id);
        $self->_tail_seen('');
        $self->_tail_stream(undef);
    });

    $self->_tail_stream($stream);
    $app->log->debug( sprintf('connected tail stream %s', $stream_id ) );
}

sub register {
    my $plugin = shift;
    my ( $app, $args ) = @_;

    $plugin->file( $args->{file} || '' );
    $plugin->webtailrc( $args->{webtailrc} || '' );
    $plugin->tail_opts( $args->{tail_opts} || DEFAULT_TAIL_OPTIONS );

    $app->routes->websocket(
        '/ws/release/progress' => sub {
            my $c = shift;
            my $tx = $c->tx;
            $plugin->_prepare_stream($app);
            $plugin->_clients->{"$tx"} = $tx;
            $c->app->log->debug( sprintf('connected %s', "$tx" ) );
            Mojo::IOLoop->stream( $tx->connection )->timeout(300)->on(
                timeout => sub {
                    $c->finish;
                    delete $plugin->_clients->{"$tx"};
                    $c->app->log->debug( sprintf('timeout %s', $tx ) );
            });
            $c->on( message => sub {
                $c->app->log->debug( sprintf('message "%s" from %s', $_[1], $tx ) );
            } );
            $c->on( finish => sub {
                delete $plugin->_clients->{"$tx"};
                $c->app->log->debug( sprintf('finish %s', $tx ) );
            } );
            $c->res->headers->content_type('text/event-stream');
            $c->send($plugin->_tail_seen);
        }
    );

    $app->routes->get(
        '/release/progress' => sub {
            my $c = shift;
            my $ws_url = $c->req->url->to_abs->scheme('ws')->to_string;
            $ws_url =~ s{\K/release/progress}{/ws};
            $c->render(
                inline    => $plugin->template,
                ws_url    => $ws_url,
                webtailrc => ( $plugin->webtailrc )
                    ? slurp( $plugin->webtailrc ) : '',
                file      => $args->{file} || 'STDIN',
            );
        },
    );
    return $app;
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::R6Tail - display build log in browser

=head1 DESCRIPTION

This code is a modified version of
https://metacpan.org/pod/Mojolicious::Plugin::Webtail

by hayajo E<lt>hayajo@cpan.orgE<gt>

published under: This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Modifications made the code tailored for R6-specific use.

=cut

1;

__END__
