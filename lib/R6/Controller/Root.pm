package R6::Controller::Root;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;
    $self->stash( tickets => [ $self->rt->all ] );
}

1;
