package R6::Model::RT;

use Carp qw/croak/;
use File::Spec::Functions qw/catfile/;
use FindBin; FindBin->again;
use R6::Model::Schema;
use Mojo::Util qw/decode/;
use List::UtilsBy qw/nsort_by/;
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
        my $schema = R6::Model::Schema->connect(
            'dbi:SQLite:' . $db_file, '', '', { sqlite_unicode => 1 },
        );
        $schema->deploy unless $exists_db_file;
        $schema;
    }
);

sub add {
    my ( $self, @data ) = @_;
    @data or return $self;

    my $db = $self->_db;
    for my $ticket ( @data ) {
        $ticket->{tags}->@* or $ticket->{tags} = ['UNTAGGED'];

        $db->resultset('Ticket')->update_or_create({
            ticket_id   => decode('UTF-8', $ticket->{id}),
            subject     => decode('UTF-8', $ticket->{subject}),
            tags        => decode('UTF-8', (join "\n", $ticket->{tags}->@*)),
            creator     => decode('UTF-8', $ticket->{creator}),
            created     => decode('UTF-8', $ticket->{created}),
            lastupdated => decode('UTF-8', $ticket->{lastupdated}),
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
    $self->_db->resultset('Ticket')->search({}, {
        result_class => 'DBIx::Class::ResultClass::HashRefInflator'
    })->all;
}

sub tags {
    my ($self, @tags) = @_;
    # TODO: fix this stupid shit with proper DBIC query
    my $re = '^' . (join '|', map +(quotemeta uc), @tags) . '$';
    nsort_by { -$_->{ticket_id} } grep {
        my $tags = $_->{tags};
        @tags == (grep $tags =~ /^\Q$_\E$/m, @tags);
    } $self->all;
}

1;