package R6;

# VERSION

use Mojo::Base 'Mojolicious';
sub startup {
    my $self = shift;
    $self->moniker('P6');
    $self->plugin('Config');
    $self->secrets([ $self->config('mojo_secrets') ]);
    $self->plugin( AssetPack => { pipes => [qw/Sass JavaScript Combine/] } );
    $self->asset->process(
        'app.css' => qw{
            /sass/bootstrap.css
            /sass/main.scss
        },
    );

    $self->asset->process(
        'app.js' => qw{
            /js/main.js
        },
    );
    my $r = $self->routes;
    { # Root routes
        $r->get('/')->to('root#index');
    }

    # { # User section routes
    #     $r->post('/login' )->to('user#login' );
    #     $r->any( '/logout')->to('user#logout');
    #
    #     my $ru = $r->under('/user')->to('user#is_logged_in');
    #     $ru->get('/')->to('user#index')->name('user/index');
    # }
}

1;

__END__
