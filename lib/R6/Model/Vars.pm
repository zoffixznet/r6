package R6::Model::Vars;

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

sub save {
    my ( $self, $name, $value ) = @_;

    $self->_db->resultset('Var')->update_or_create({
        name  => $name,
        value => $value,
    });

    $value;
}

sub var {
    my ( $self, $name ) = @_;
    my $value = (
        (
            $self->_db->resultset('Var')->search({
                name => $name
            }, {
                result_class => 'DBIx::Class::ResultClass::HashRefInflator'
            })->all
        )[0] || {}
    )->{value};
    return $value;
}



1;