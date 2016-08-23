package R6::Model::RT;

use Carp qw/croak/;
use File::Spec::Functions qw/catfile/;
use FindBin; FindBin->again;
use R6::Model::RT::Schema;
use Mew;

has db_file => Str | InstanceOf['File::Temp'], (
    is      => 'lazy',
    default => sub { $ENV{R6_DB_FILE} // catfile $FindBin::Bin, qw/.. r6.db/ },
);

has _db => (
    is      => 'lazy',
    default => sub {
        my $db_file = shift->db_file;
        my $exists_db_file = -e $db_file;
        my $schema = R6::Model::RT::Schema->connect(
            'dbi:SQLite:' . $db_file, '', '', { sqlite_unicode => 1 },
        );
        $schema->deploy unless $exists_db_file;
    }
);

sub add {
    my ( $self, @data ) = @_;
    @data or return $self;

    my $db = $self->_db;
    for my $ticket ( @data ) {
        $ticket->{tags} ||= ['UNTAGGED'];

        $db->resultset('Dist')->update_or_create({
            travis   => { status => $ticket->{travis_status} },
            author => { # use same field for both, for now. TODO:fetch realname
                author_id => $ticket->{author_id}, name => $ticket->{author_id},
            },
            dist_build_id => { id => $ticket->{build_id} },
            map +( $_ => $ticket->{$_} ),
                qw/name  meta_url  url  description  stars  issues
                    date_updated  date_added/,
        });
    }

    $self;
}

