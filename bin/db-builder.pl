use strict;
use warnings;
use 5.024;
use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use POSIX qw/strftime/;
use File::Spec::Functions qw/catfile/;
use R6::Model::RT;
use R6::Model::Vars;
use R6::RT::Client::REST::Lazy;

my $conf = do "$FindBin::Bin/../R6.conf" or die 'Failed to load R6.conf';
my $rt = R6::RT::Client::REST::Lazy->new(
    login => $conf->{rt}{login},
    pass  => $conf->{rt}{pass},
);
my $model_rt  = R6::Model::RT->new;
my $model_var = R6::Model::Var->new;

# Save fetch date before starting the request, so we don't lose stuff if
# the requests fails

my $last_fetch_date = $model_var->var('db_last_updated') // 0;
$last_fetch_date = strftime "%Y-%m-%d", localtime $last_fetch_date
    if $last_fetch_date;

my $fetch_date = time;
my @tickets = $rt->search(
    $last_fetch_date ? ( updated_after => $last_fetch_date ) : ()
);
say 'Found ' . @tickets . ' tickets';

$model_rt->add(@tickets);
$model_var->save( db_last_updated => $fetch_date );


__END__


