package R6::RT::Client::REST::Lazy;
use Mew;
use Mojo::Util qw/trim/;
use Mojo::UserAgent;
use URI::Escape;

has [qw/_login  _pass/] => Str;
has _server => Str, default => 'https://rt.perl.org/REST/1.0';
has _ua => (
    InstanceOf['Mojo::UserAgent'],
    default => sub { Mojo::UserAgent->new },
);

has _lp => (
    Str, is => 'lazy',
    default => sub {
        my $self = shift;
        return 'user=' . $self->_login . '&pass=' . $self->_pass
    },
);

sub search {
    my ($self, %opts) = @_;
    $opts{not_status} = ['resolved', 'rejected']
        unless $opts{status} or $opts{not_status};

    my $cond = join " AND ",
        ($opts{after}  ? "Created >= '$opts{after}'"  : () ),
        ($opts{before} ? "Created < '$opts{before}'"  : () ),
        ($opts{status}
            ? "("
                . (join ' OR ', map "Status = '$_'", $opts{status}->@*)
                . ")"
            : ()
        ),
        ($opts{not_status}
            ? (map "Status != '$_'", $opts{not_status}->@*)
            : ()
        );

    my $url = $self->_server . '/search/ticket?' . $self->_lp
        . '&orderby=-Created'
        . '&query=' . uri_escape("Queue = 'perl6' AND ($cond)");

    my $tx = $self->_ua->get($url);
    return 0 unless $tx->success;
    my $c = $tx->res->body;
    return 0 unless $c =~ s{^RT/[\d.]+ 200 Ok\s+}{};
    $c = trim $c;

    my @tickets;
    for ( split /\r?\n\r?/, $c ) {
        next unless /^\d+:.+/;
        my ( $id, $subject ) = split /: /, $_, 2;
        my @tags = $subject =~ /\[ [^\]]+ \]/gx;
        push @tickets, {
            id      => $id,
            subject => $subject,
            tags    => \@tags,
        };
    }
    use Acme::Dump::And::Dumper;
    print DnD \@tickets;
}

sub ticket {
    my ($self, $id) = @_;
    my $url = $self->_server . '/ticket/' . $id
        . '/history?format=l&' . $self->_lp;


    my $tx = $self->_ua->get($url);
    return 0 unless $tx->success;
    my $c = $tx->res->body;
    use Acme::Dump::And::Dumper;
    print DnD [ $c ];
}

1;