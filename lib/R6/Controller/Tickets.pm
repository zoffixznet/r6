package R6::Controller::Tickets;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw/trim/;

sub tag_action {
    my $self = shift;
    my @tags = map uc, grep length, split /\s*,\s*/, trim $self->stash('tag');

    # TODO: replace with saner logic, factor this out into one place
    my @tickets = $self->rt->all;
    my %tags; $tags{$_}++ for map split(' ', $_->{tags}), @tickets;
    my @tagged_tickets = $self->rt->tags(\@tags, \@tickets);
    $self->stash(
        tags => [
            map +{ tag => $_, count => $tags{$_} }, sort keys %tags
        ],
        tickets => \@tagged_tickets,
    );

    $self->respond_to(
        html => {template => 'tickets/tag'},
        json => {
            json => {
                total => scalar(@tagged_tickets),
                tag   => join(', ', @tags),
                url   => $self->url_for('/t/' . join(',', @tags))->to_abs,
            },
        },
    );
}

sub mark_reviewed {
    my $self = shift;
    return $self->reply->not_found unless ($self->user)[1];
    $self->rt->toggle_reviewed( $self->param('ticket_id') );
    $self->redirect_to( $self->req->headers->referrer );
}

sub mark_blocker {
    my $self = shift;
    return $self->reply->not_found unless ($self->user)[1];
    $self->rt->toggle_blocker( $self->param('ticket_id') );
    $self->redirect_to( $self->req->headers->referrer );
}

sub view_ticket {
    my $self = shift;
    $self->redirect_to(
        'https://rt.perl.org/Ticket/Display.html?id=' . $self->stash('ticket')
    );
}

sub mark_commit_as_added {
    my $self = shift;
    return $self->reply->not_found unless ($self->user)[1];
    $self->rakudo_commits->toggle_added( $self->param('sha') );
    $self->redirect_to( $self->req->headers->referrer );
}

1;
