use strict;
use warnings;
use 5.024;
use Pithub;
use LWP::UserAgent;

my $conf = do 'R6.conf' or die "Failed to load config";

my $pit = Pithub->new(
    user  => 'rakudo',
    repo  => 'rakudo',
    token => $conf->{github}{token},
);


my $c = $pit->repos->commits->compare(
    base => '2016.08.1',
    head => 'nom',
);

die 'Failed to get commits: ' . $c->code unless $c->success;
my @commits = map +{
    url     => $_->{commit}{tree}{url},
    sha     => $_->{sha},
    author  => $_->{commit}{author}{name},
    message => $_->{commit}{message},
    date    => $_->{commit}{author}{date},
}, $c->content->{commits}->@*;

use Acme::Dump::And::Dumper;
die DnD [ @commits ];