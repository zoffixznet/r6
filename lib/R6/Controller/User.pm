package R6::Controller::User;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;
    my @tickets = $self->rt->all;
    my %tags; $tags{$_}++ for map split(' ', $_->{tags}), @tickets;
    $self->stash(
        tags => [
            map +{ tag => $_, count => $tags{$_} },
                sort { $tags{$b} <=> $tags{$a} or $a cmp $b } keys %tags
        ],
        tickets => \@tickets
    );
}

1;
