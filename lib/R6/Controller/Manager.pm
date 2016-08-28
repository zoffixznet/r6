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

    my $blockers = grep $_->{is_blocker}, @tickets;
    my $reviewed = grep $_->{is_reviewed}, @tickets;

    my %info = (
        when_release => $when_release,
        tickets      => \@tickets,
        blockers     => $blockers,
        unreviewed   => @tickets - $reviewed,
    );

    $self->stash(%info);
    $self->respond_to(
        html => { template => 'manager/release_stats' },
        json => { json => {
                %info{qw/when_release  blockers  unreviewed/},
                total_tickets => 0+@tickets,
                url => $self->url_for('/release/stats')->to_abs,
            },
        },
    );
}

1;
