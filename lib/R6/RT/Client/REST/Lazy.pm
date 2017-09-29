package R6::RT::Client::REST::Lazy;
use 5.024;

use Mew;
use Mojo::Util qw/trim/;
use Mojo::UserAgent;
use URI::Escape;
use List::Util qw/uniq/;
use Date::Manip;
use Mojo::UserAgent::CookieJar;
use Mojo::Cookie::Response;
use Mojo::URL;


has [qw/_login  _pass/] => Str, ( required => 0 );
has _server => Str, default => 'https://rt.perl.org/REST/1.0';
sub _ua {
    Mojo::UserAgent->new(
        connect_timeout    => 60,
        inactivity_timeout => 600,
        request_timeout    => 600,
        max_redirects      => 10,
    );
}

sub _lp {
    my $self = shift;
    my ($login, $pass) = @_ ? @_ : ($self->_login, $self->_pass);
    return 'user=' . uri_escape($login) . '&pass=' . uri_escape($pass);
}

sub search {
    my ($self, %opts) = @_;
    $opts{not_status} = ['resolved', 'rejected', 'stalled']
        unless exists $opts{status} or exists $opts{not_status};
    $opts{format} //= 'l';

    # Figure out a way to use the LastUpdated thing to fetch only the needed
    # Info for tickets and not the full queue each time
    # LastUpdated

    my $cond = join " AND ",
        (
            $opts{updated_after}
                ? "LastUpdated >= '$opts{updated_after}'"  : ()
        ),
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

    $cond = "AND ($cond)" if $cond;

    my $url = $self->_server . '/search/ticket?' . $self->_lp
        . '&orderby=-Created'
        . '&format=' . $opts{format}
        . '&query=' . uri_escape("Queue = 'perl6' $cond");

    my $tx = $self->_ua->get($url);
    return unless $tx->success;
    my $c = $tx->res->body;
    return unless $c =~ s{^RT/[\d.]+ 200 Ok\s+}{};
    $c = trim $c;
    return if $c eq 'No matching results.';

    my @tickets;
    if ( $opts{format} eq 's' ) {
        # this branch is not really used any more
        for ( split /\r?\n\r?/, $c ) {
            next unless /^\d+:.+/;
            my ( $id, $subject ) = split /: /, $_, 2;
            my @tags = map uc, $subject =~ /(?<=\[) [\@A-Z]+ (?=\])/gx;
            push @tickets, {
                id      => $id,
                subject => $subject,
                tags    => \@tags,
            };
        }
    }
    elsif ( $opts{format} eq 'l') {
        for ( split /\n\n--\n\n/xm, $c ) {
            my %ticket;
            for ( split /\n/ ) {
                next unless length;
                my ($key, $value) = split /:\s+/, $_, 2;
                $ticket{lc $key} = $value // '';
            }
            ( $ticket{id} ) = $ticket{id} =~ /\d+/g;

            # We take tags from cf.{tag} field and then take some from the
            # subject line: case doesn't matter for tags at the start of the
            # subject line (and we strip those tags from the subject), but
            # case DOES matter for any tags that appear in the middle of the
            # subject line, as letting them be anything interferes with random
            # text, giving us bogus tags.
            my @tags = grep length, split /,/, $ticket{'cf.{tag}'}//'';
            my $tag_re_i = qr/\[ [\@A-Z0-9.]+ \]/ix;
            while (
                $ticket{subject} =~ s/^ \s* $tag_re_i*? ($tag_re_i) \s* //gx
            ) {
                push @tags, $1;
            }
            @tags = map s/[\[\]]//gr, @tags;
            $ticket{tags} = [ sort +uniq map uc, @tags ];

            # filter out stuff we don't use yet
            push @tickets, +{
                map +( $_ => $ticket{$_} ), qw/
                    tags  id  subject  creator  created  lastupdated  status
                /
            };
        }
    }
    # use Acme::Dump::And::Dumper;
    # print DnD [ @tickets ];
    return @tickets;
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

sub check_cookie {
    my ($self, $cookie) = @_;

    my $jar = Mojo::UserAgent::CookieJar->new;
    my $origin = Mojo::URL->new( $self->_server )->host;
    $jar->add(
        Mojo::Cookie::Response->new->parse($cookie)
            ->[0]->origin($origin)
    );

    my $tx = Mojo::UserAgent->new( cookie_jar => $jar )->get(
        $self->_server . '/ticket/1'
    );

    return -1 unless $tx->success;
    return 1 if $tx->res->body =~ m{\A RT/ [\d.]+ \s+ 200 \s+ Ok $}xm;
    return 0;
}

sub check_credentials {
    my ($self, $login, $pass) = @_;
    my $tx = $self->_ua->post(
        $self->_server, form => {
            user => $login,
            pass => $pass,
        }
    );
    return unless $tx->success;
    return +(map $_->to_string, $tx->res->cookies->@*)[0]
        if $tx->res->body =~ m{\A RT/ [\d.]+ \s+ 200 \s+ Ok $}xm;

    return;
}

1;

__END__

  {
    'cf.{platform}' => '',
    'timeestimated' => '0',
    'requestors' => 'cmasak@gmail.com',
    'resolved' => 'Not set',
    'cf.{severity}' => '',
    'subject' => '[BUG] Missing bit in error message about R?? in Rakudo',
    'queue' => 'perl6',
    'told' => 'Not set',
    'cf.{tag}' => 'Bug',
    'started' => 'Not set',
    'lastupdated' => 'Thu Aug 25 03:18:26 2016',
    'creator' => 'masak',
    'initialpriority' => '0',
    'created' => 'Thu Aug 25 03:18:26 2016',
    'finalpriority' => '0',
    'cf.{patch status}' => '',
    'cc:' => '',
    'timeleft' => '0',
    'due' => 'Not set',
    'priority' => '0',
    'admincc:' => '',
    'tags' => [
                'BUG'
              ],
    'cf.{vm}:' => '',
    'status' => 'new',
    'starts' => 'Not set',
    'id' => '129080',
    'timeworked' => '0',
    'owner' => 'Nobody'
  }
