package R6::Controller::Manager;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw/to_json/;

sub settings {
    my $self = shift;
    $self->vars( last_release_date => $self->param('last_release_date') );
    $self->redirect_to( $self->req->headers->referrer );
}

1;
