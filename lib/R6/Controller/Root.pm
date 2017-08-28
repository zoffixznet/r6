package R6::Controller::Root;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;
    my @tickets = $self->rt->all;
    my %tags; $tags{$_}++ for map split(' ', $_->{tags}), @tickets;

    my @tags = map +{ tag => $_, count => $tags{$_} },
                sort { $tags{$b} <=> $tags{$a} or $a cmp $b } keys %tags;
    $self->stash(
        tags    => \@tags,
        tickets => \@tickets
    );

    $self->respond_to(
        html => {template => 'root/index'},
        json => {
            json => {
                total => scalar(@tickets),
                tags  => \@tags,
                url   => $self->url_for('/')->to_abs,
                ($self->param('full') ? tickets => \@tickets : ()),
            },
        },
    );
}

1;
