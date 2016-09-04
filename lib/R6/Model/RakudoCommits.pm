package R6::Model::RakudoCommits;

use 5.024;
use Carp qw/croak/;
use File::Spec::Functions qw/catfile/;
use FindBin; FindBin->again;
use R6::Model::Schema;
use Pithub;
use Mojo::Util qw/decode/;
use List::UtilsBy qw/nsort_by/;
use Mew;
use Date::Manip;

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
    my ( $self, @commits) = @_;
    @commits or return $self;

    my $db = $self->_db;
    for my $commit ( @commits ) {
        $commit->{date} = UnixDate($commit->{date}, '%s')//0;
        $db->resultset('RakudoCommits')->update_or_create({
            date => 0+$commit->{date}, # force numeric
            map +( $_ => $commit->{$_} ), qw/sha  url  author  message/,
        });
    }

    $self;
}

sub all {
    my $self = shift;
    nsort_by { -$_->{date} } $self->_db->resultset('RakudoCommits')
        ->search({}, {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        })->all;
}

sub toggle_added {
    my ( $self, $sha ) = @_;

    my $rs = $self->_db->resultset('RakudoCommits')->search({
        sha => $sha,
    });
    $rs->update({ is_added => ! $rs->next->is_added });
}

1;