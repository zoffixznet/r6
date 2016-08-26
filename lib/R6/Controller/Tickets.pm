package R6::Controller::Tickets;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw/trim/;

sub tag {
    my $self = shift;
    my @tags = grep length, split /\s*,\s*/, trim $self->stash('tag');

    # TODO: replace with saner logic, factor this out into one place
    my @tickets = $self->rt->all;
    my %tags; $tags{$_}++ for map split(' ', $_->{tags}), @tickets;
    $self->stash(
        tags => [
            map +{ tag => $_, count => $tags{$_} },
                sort { $tags{$b} <=> $tags{$a} or $a cmp $b } keys %tags
        ],
        tickets => [ $self->rt->tags(\@tags, \@tickets) ],
    );
}

sub mark_reviewed {
    my $self = shift;
    $self->rt->set_reviewed( $self->param('ticket_id') );
    $self->redirect_to( $self->req->headers->referrer );
}

sub mark_blocker {
    my $self = shift;
    $self->rt->set_blocker( $self->param('ticket_id') );
    $self->redirect_to( $self->req->headers->referrer );
}

1;
