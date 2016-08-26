package R6::Controller::User;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw/to_json/;

sub login {
    my $self = shift;

    use Acme::Dump::And::Dumper;
    print DnD [ $self->param('login'), $self->param('pass') ];

    my $cookie = $self->rt->get_cookie(
        $self->param('login'), $self->param('pass')
    ) or return $self->redirect_to('/failed-login');

    my $is_manager
    = $self->config('release_managers')->{ $self->param('login') };

    my %data = ( rt_cookie => $cookie );
    $data{manager} = 1 if $is_manager;

    eval {
        $self->session(
            rt_data => $self->crypt->encode( to_json \%data )
        );
        $self->stash(
            login_success => 1,
            manager       => $is_manager,
        );
        1;
    } or return $self->redirect_to('/failed-login');

    $self->redirect_to('/');
}

sub logout {
    my $self = shift;
    $self->session(expires => 1);
    $self->redirect_to('/');
}

1;
