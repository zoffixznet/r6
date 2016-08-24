use strict;
use warnings;
use 5.024;
use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use File::Spec::Functions qw/catfile/;
use R6::Model::RT;
use R6::RT::Client::REST::Lazy;

my $conf = do "$FindBin::Bin/../R6.conf" or die 'Failed to load R6.conf';
my $rt = R6::RT::Client::REST::Lazy->new(
    login => $conf->{rt}{login},
    pass  => $conf->{rt}{pass},
);
my $model = R6::Model::RT->new;
my @tickets = $rt->search; #( after => '2016-08-20' );
say 'Found ' . @tickets . ' tickets';
$model->add(@tickets);


