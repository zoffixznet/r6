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

    my $time_until_release = denominal(
        $next_release - time, \'time', { precision => 2 },
    );

    my @tickets = grep {
        UnixDate($_->{created}, '%s') >= $last_release
    } $self->rt->all;

    my $blockers = grep $_->{is_blocker}, @tickets;
    my $reviewed = grep $_->{is_reviewed}, @tickets;

    my %info = (
        time_until_release => $time_until_release,
        tickets            => \@tickets,
        blockers           => $blockers,
        unreviewed         => @tickets - $reviewed,
    );

    $self->stash(%info);
    $self->respond_to(
        html => { template => 'manager/release_stats' },
        json => { json => \%info, },
    );
}

1;
