package R6::Model::RT;

use Carp qw/croak/;
use File::Spec::Functions qw/catfile/;
use FindBin; FindBin->again;
use R6::Model::Schema;
use R6::RT::Client::REST::Lazy;
use Mojo::Util qw/decode/;
use List::UtilsBy qw/nsort_by/;
use Mew;

has _rt => InstanceOf['R6::RT::Client::REST::Lazy'], (
    is => 'lazy',
    default => sub { R6::RT::Client::REST::Lazy->new },
);

has db_file => Str | InstanceOf['File::Temp'], (
    is      => 'lazy',
    default => sub { $ENV{R6_DB_FILE} // catfile $FindBin::Bin, qw/.. r6.db/ },
);

has _db => (
    is      => 'lazy',
    default => sub {
        my $db_file = shift->db_file;
        my $exists_db_file = -e $db_file;
        my $schema = R6::Model::Schema->connect(
            'dbi:SQLite:' . $db_file, '', '', { sqlite_unicode => 1 },
        );
        $schema->deploy unless $exists_db_file;
        $schema;
    }
);

sub set_reviewed {
    my ( $self, $ticket_id, $status ) = @_;

    $self->_db->resultset('Ticket')->search({
        ticket_id => $ticket_id,
    })->update({ is_reviewed => $status//1 });
}

sub set_blocker {
    my ( $self, $ticket_id, $status ) = @_;

    $self->_db->resultset('Ticket')->search({
        ticket_id => $ticket_id,
    })->update({ is_blocker => $status//1 });
}

sub delete {
    my ( $self, @ids ) = @_;
    @ids or return;
    $self->_db->resultset('Ticket')
        ->search({ ticket_id => \@ids })->delete_all;

    $self;
}

sub add {
    my ( $self, $tickets, %opts ) = @_;
    @$tickets or return $self;

    my $db = $self->_db;
    for my $ticket ( @$tickets ) {
        $ticket->{tags}->@* or $ticket->{tags} = ['UNTAGGED'];

        $db->resultset('Ticket')->update_or_create({
            ticket_id   => decode('UTF-8', $ticket->{id}),
            subject     => decode('UTF-8', $ticket->{subject}),
            tags        => decode('UTF-8', (join "\n", $ticket->{tags}->@*)),
            creator     => decode('UTF-8', $ticket->{creator}),
            created     => decode('UTF-8', $ticket->{created}),
            lastupdated => decode('UTF-8', $ticket->{lastupdated}),

            ( $opts{all_reviewed} ? ( is_reviewed => 1 ) : () ),
        });

        # $db->resultset('Ticket')->update_or_create({
        #     ticket_id => $ticket->{id},
        #     subject   => $ticket->{subject},
        #     ticket_tag      => [ map +{ tag => $_ }, $ticket->{tags}->@* ],
        # }, {
        #     # join => 'tags',
        #     # prefetch => [
        #     #     { tags => 'ticket_tag' },
        #     # ],
        # });
    }

    $self;
}

sub all {
    my $self = shift;
    nsort_by { -$_->{ticket_id} } $self->_db->resultset('Ticket')->search({}, {
        result_class => 'DBIx::Class::ResultClass::HashRefInflator'
    })->all;
}

sub tags {
    my ($self, $tags, $source) = @_;
    # TODO: fix this stupid shit with proper DBIC query
    nsort_by { -$_->{ticket_id} } grep {
        my $ticket_tags = $_->{tags};
        @$tags == (grep $ticket_tags =~ /^\Q$_\E$/m, map uc, @$tags);
    } $source ? @$source : $self->all;
}

sub get_cookie {
    my ($self, $login, $pass) = @_;
    return $self->_rt->check_credentials($login, $pass);
}

1;