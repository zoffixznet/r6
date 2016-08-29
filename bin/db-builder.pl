use strict;
use warnings;
use 5.022;
use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use POSIX qw/strftime/;
use File::Spec::Functions qw/catfile/;
use Getopt::Long;
use R6::Model::RT;
use R6::Model::Vars;
use R6::RT::Client::REST::Lazy;

GetOptions(
    'rebuild' => \my $is_rebuild,
);

say "Rebuild option was passed. Ensure you deleted old database file!!"
    if $is_rebuild;

my $conf = do "$FindBin::Bin/../R6.conf" or die 'Failed to load R6.conf';
my $rt = R6::RT::Client::REST::Lazy->new(
    login => $conf->{rt}{login},
    pass  => $conf->{rt}{pass},
);
my $model_rt  = R6::Model::RT->new;
my $model_var = R6::Model::Vars->new;

# Save fetch date before starting the request, so we don't lose stuff if
# the requests fails

my $last_fetch_date = $model_var->var('db_last_updated') // 0;
$last_fetch_date = strftime '%Y-%m-%d', localtime $last_fetch_date
    if $last_fetch_date;

say "Fetching tickets updated since $last_fetch_date";
my $fetch_date = time;

# If we are rebuilding from scratch, fetch only tickets with wanted statuses.
# If we are NOT rebuilding from scratch, fetch changed tickets with ALL
# statuses, and delete those with unwanted statuses from the database.
if ( $is_rebuild ) {
    my @tickets = $rt->search;
    say 'Found ' . @tickets . ' tickets';
    $model_rt->add(\@tickets, all_reviewed => 1);
}
else {
    my @all_tickets = $rt->search(
        status     => undef,
        not_status => undef,
        ($last_fetch_date ? ( updated_after => $last_fetch_date ) : ()),
    );
    say 'Found ' . @all_tickets . ' total tickets';
    my (@to_delete, @to_add);
    for ( @all_tickets ) {
        $_->{status} =~ /^(rejected|resolved|stalled|deleted)$/
            ? (push @to_delete, $_->{id})
            : (push @to_add,    $_);
    }
    say 'Have ' . @to_delete . ' tickets to delete and ' . @to_add
        . ' tickets to add';
    $model_rt->delete(@to_delete);
    $model_rt->add(\@to_add);
}

$model_var->save( db_last_updated => $fetch_date );


__END__


