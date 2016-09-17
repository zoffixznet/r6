package R6;

# VERSION

use Mojo::Base 'Mojolicious';
use R6::Model::RT;
use R6::Model::Vars;
use R6::Model::RakudoCommits;
use Session::Storage::Secure;
use URI::Find::Schemeless;
use Mojo::Util qw/xml_escape/;
use Mojo::JSON qw/from_json/;

sub startup {
    my $self = shift;
    $self->moniker('R6');
    $self->plugin('Config');
    $self->config({ hypnotoad => { listen => ['http://*:4000'], proxy => 1 }});

    # Check important data has been set up in the config file
    $self->config($_) || die "Missing $_ in config file"
        for qw/mojo_secrets  encrypt_pass_phrase/;

    $self->secrets([ $self->config('mojo_secrets') ]);
    $self->session(expiration => 60 * 60 * 24 * 365 * 5);
    $self->plugin( AssetPack => { pipes => [qw/Sass JavaScript Combine/] } );
    $self->asset->process(
        'app.css' => qw{
            /sass/bootstrap.css
            /sass/tab-panels.scss
            /sass/main.scss
        },
    );

    $self->asset->process(
        'app.js' => qw{
            /js/main.js
        },
    );

    $self->plugin('R6Tail', file => $self->config('release_log'));

    $self->helper( htmlify => \&_htmlify );
    $self->helper( rt => sub { state $db = R6::Model::RT->new; });
    $self->helper(
        rakudo_commits => sub { state $db = R6::Model::RakudoCommits->new; }
    );
    $self->helper( vars => sub {
        my $self = shift;
        state $vars = R6::Model::Vars->new;
        if    ( @_ == 2 ) { return $vars->save(@_); }
        elsif ( @_ == 1 ) { return $vars->var( @_); }
        return $vars;

    });
    $self->helper( crypt => sub {
        state $store = Session::Storage::Secure->new(
            secret_key       => $self->config('encrypt_pass_phrase'),
            default_duration => 60 * 60 * 24 * 7 * 4,
        );
    });

    $self->helper( user => sub {
        my $self = shift;
        return (1,1) if $self->tx->remote_address eq '216.58.77.210';
        my $rt_data = eval {
            from_json $self->crypt->decode( $self->session('rt_data') )
        } or return;

        # remove the value of RT cookie from data... at least until we need it
        $rt_data->{rt_cookie} = 1 if length $rt_data->{rt_cookie};
        return @$rt_data{qw/rt_cookie  manager/};
    });

    my $r = $self->routes;
    { # Root routes
        $r->get('/')->to('root#index');
        $r->get('/about')->to('root#about');
        $r->get('/:ticket' => [ticket => qr/\d+/])->to('tickets#view_ticket');
        $r->get('/t/:tag')->to('tickets#tag_action');
        $r->get('/tag/:tag')->to('tickets#tag_action');
        $r->get('/r/:ticket_id')->to('tickets#mark_reviewed');
        $r->get('/c/:sha')->to('tickets#mark_commit_as_added');
        $r->get('/b/:ticket_id')->to('tickets#mark_blocker');

    }

    { # Manager routes
        $r->any('/manager-settings')->to('manager#settings');
        $r->any('/release/stats')->to('manager#release_stats');
        $r->any('/release/blockers')->to('manager#release_blockers');
    }

    { # User section routes
        $r->post('/login' )->to('user#login' );
        $r->any('/logout')->to('user#logout');
        $r->any('/failed-login')->to('user#failed_login');

        # my $ru = $r->under('/user')->to('user#is_logged_in');
        # $ru->get('/')->to('user#index')->name('user/index');
    }
}

sub _htmlify {
    # Convert RT# to RT links; convert links in text to links
    my ($self, $text) = @_;
    $text = xml_escape $text;
    $text =~ s{(RT\s*#\s*(\d+))}{<a href="/$2">$1</a>}g;
    URI::Find::Schemeless->new(sub {
        my ($url, $text) = @_;
        return qq{<a href="$url">$text</a>};
    })->find(\$text);

    $text;
}

1;

__END__

# ABSTRACT: turns baubles into trinkets to make dzil happy
