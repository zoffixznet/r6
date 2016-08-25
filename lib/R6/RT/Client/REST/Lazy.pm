package R6::RT::Client::REST::Lazy;
use 5.024;

use Mew;
use Mojo::Util qw/trim/;
use Mojo::UserAgent;
use URI::Escape;
use List::Util qw/uniq/;
use Date::Manip;


has [qw/_login  _pass/] => Str;
has _server => Str, default => 'https://rt.perl.org/REST/1.0';
has _ua => (
    InstanceOf['Mojo::UserAgent'],
    default => sub {
        Mojo::UserAgent->new(
            connect_timeout    => 60,
            inactivity_timeout => 60,
            request_timeout    => 600,
        );
    },
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
    $opts{not_status} = ['resolved', 'rejected', 'stalled']
        unless $opts{status} or $opts{not_status};
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

    my $url = $self->_server . '/search/ticket?' . $self->_lp
        . '&orderby=-Created'
        . '&format=' . $opts{format}
        . '&query=' . uri_escape("Queue = 'perl6' AND ($cond)");

    my $tx = $self->_ua->get($url);
    return unless $tx->success;
    my $c = $tx->res->body;
    return unless $c =~ s{^RT/[\d.]+ 200 Ok\s+}{};
    $c = trim $c;
    my @tickets;
    if ( $opts{format} eq 's' ) {
        # this branch is not really used any more
        for ( split /\r?\n\r?/, $c ) {
            next unless /^\d+:.+/;
            my ( $id, $subject ) = split /: /, $_, 2;
            my @tags = $subject =~ /(?<=\[) [\@A-Z]+ (?=\])/gx;
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
            my @tags = $ticket{subject} =~ /(?<=\[) [\@A-Z]+ (?=\])/gx;
            push @tags, map uc,
                grep length, split /,/, $ticket{'cf.{tag}'}//'';

            # Strip tags from the start of the subject
            $ticket{subject} =~ s/^ (\s* \[ [\@A-Z]+ \] \s*)+//x;

            $ticket{tags} = [ sort +uniq @tags ];

            # filter out stuff we don't use yet
            push @tickets, +{
                map +( $_ => $ticket{$_} ), qw/
                    tags  id  subject  creator  created  lastupdated
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

