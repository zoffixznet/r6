use lib qw/lib/;
use R6::Model::RT;

my $conf = do 'R6.conf' or die "Failed to load config: $! $@";
my $rt = R6::Model::RT->new(
    login => $conf->{rt}{login},
    pass  => $conf->{rt}{pass},
);

$rt->show_ticket('128283');
# $rt->search;
