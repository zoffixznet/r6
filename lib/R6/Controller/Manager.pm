package R6::Controller::Manager;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw/to_json/;
use Number::Denominal;
use Date::Manip;

sub settings {
    my $self = shift;
    return $self->reply->not_found unless ($self->user)[1];

    $self->vars( $_ => $self->param($_) )
        for qw/last_release_date  next_release_date/;

    $self->redirect_to( $self->req->headers->referrer );
}

sub release_stats {
    my $self = shift;

    my ($last_release, $next_release) = map UnixDate($_, '%s')//0,
            $self->vars('last_release_date'),
            $self->vars('next_release_date');

    my $when_release = $next_release - time;
    if ( abs($when_release) <= 60*60*24 ) {
        $when_release = 'is today';
    }
    elsif ( $when_release < 0 ) {
        $when_release = 'is in the past';
    }
    else {
        $when_release = 'will be in ' . denominal(
            $when_release, \'time', { precision => 2 },
        );
    }

    my @tickets = grep {
        UnixDate($_->{created}, '%s') >= $last_release
    } $self->rt->all;

    my @commits = $self->rakudo_commits->all;

    for (@commits) {
        $_->{log_message} = '+ ' . (split /\n/, $_->{message})[0]
            . ' [' . substr($_->{sha}, 0, 8) .']';
        $_->{log_message} =~ s/(Fix|Add|Implement)/$1ed/gi;
        $_->{log_message} =~ s/(Remove)/$1d/gi;
        $_->{log_message} =~ s/Make/Made/gi;
        $_->{log_message} =~ s/\bas\ fast\b/faster/gi;
        $_->{log_message} =~ s/\Q[io grant] //;
        $_->{log_message} =~ s/(\S*?[><*]\S*)/`$1`/g;
    }

    my $blockers         = grep $_->{is_blocker},  @tickets;
    my $reviewed_tickets = grep $_->{is_reviewed}, @tickets;
    my $reviewed_commits = grep $_->{is_added},    @commits;

    my %info = (
        when_release => $when_release,
        tickets      => \@tickets,
        commits      => \@commits,
        blockers     => $blockers,
        unreviewed_tickets => @tickets - $reviewed_tickets,
        unreviewed_commits => @commits - $reviewed_commits,
    );

    $self->stash(%info);
    $self->respond_to(
        html => { template => 'manager/release_stats' },
        json => { json => {
                %info{qw/
                    when_release        blockers
                    unreviewed_tickets  unreviewed_commits
                /},
                total_tickets => 0+@tickets,
                url => $self->url_for('/release/stats')->to_abs,
            },
        },
    );
}

sub release_blockers {
    my $self = shift;

    my $last_release = UnixDate( $self->vars('last_release_date'), '%s' )//0;
    my @tickets = grep {
        $_->{is_blocker} and UnixDate($_->{created}, '%s') >= $last_release
    } $self->rt->all;


    $_->{url} = $self->url_for('/' . $_->{ticket_id})->to_abs
        for @tickets;

    $self->respond_to(
        html => { template => 'manager/release_blockers',
            blockers => 0+@tickets,
            tickets => \@tickets,
        },
        json => { json => {
                total_blockers => 0+@tickets,
                url => $self->url_for('/release/blockers')->to_abs,
                tickets => \@tickets,
            },
        },
    );
}

1;
