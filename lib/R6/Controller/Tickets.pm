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
        tickets => [ $self->rt->tags(@tags) ],
    );
}

1;
