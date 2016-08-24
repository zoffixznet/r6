package R6::Controller::Tickets;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw/trim/;

sub tag {
    my $self = shift;
    my @tags = grep length, split /\s*,\s*/, trim $self->stash('tag');
    $self->stash( tickets => [ $self->rt->tags(@tags) ] );
}

1;
