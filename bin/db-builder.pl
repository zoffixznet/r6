use strict;
use warnings;
use 5.024;
use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use POSIX qw/strftime/;
use File::Spec::Functions qw/catfile/;
use Getopt::Long;
use Pithub;
use R6::Model::RT;
use R6::Model::RakudoCommits;
use R6::Model::Vars;
use R6::RT::Client::REST::Lazy;

GetOptions(
    'rebuild' => \my $is_rebuild,
    'help'    => sub { say '--rebuild'; exit; },
);

say "Rebuild option was passed. Ensure you deleted old database file!!"
    if $is_rebuild;

my $conf = do "$FindBin::Bin/../R6.conf" or die 'Failed to load R6.conf';
my $rt = R6::RT::Client::REST::Lazy->new(
    login => $conf->{rt}{login},
    pass  => $conf->{rt}{pass},
);
my $model_rt  = R6::Model::RT->new;
my $model_com = R6::Model::RakudoCommits->new;
my $model_var = R6::Model::Vars->new;

fetch_tickets_gist($rt, $model_rt, $model_var, $is_rebuild);
fetch_rakudo_commits($conf, $model_com);
say "Finished";

##########################################################################

sub fetch_rakudo_commits {
    my ($conf, $model_com) = @_;
    my $rakudo_user   = $conf->{github}{rakudo_user}
                      // die('{github}{rakudo_user} missing from R6.conf');
    my $rakudo_repo   = $conf->{github}{rakudo_repo}
                      // die('{github}{rakudo_repo} missing from R6.conf');
    my $github_token  = $conf->{github}{token}
                      // die('{github}{token} missing from R6.conf');
    my $master_branch = $conf->{github}{master_branch}
                      // die('{github}{master_branch} missing from R6.conf');

    my $pit = Pithub->new(
        user  => $rakudo_user,
        repo  => $rakudo_repo,
        token => $github_token,
    );

    # Fetch last commit we know of from DB. If it's missing, use a known tag
    # (tag choice is the last release tag when this app was written; can
    # be freely updated to latest release, to reduce the number of commits
    # we fetch on fresh DB build)
    my $newest_commit = ($model_com->all)[0] // {};
    my $c = $pit->repos->commits->compare(
        base => $newest_commit->{sha} // '2017.05',
        head => $master_branch,
    );

    unless ($c->success) {
        warn 'Failed to get commits: ' . $c->code;
        return;
    }

    my @commits = map +{
        url     => $_->{commit}{tree}{url},
        sha     => $_->{sha},
        author  => $_->{commit}{author}{name},
        message => $_->{commit}{message},
        date    => $_->{commit}{author}{date},
    }, $c->content->{commits}->@*;

    say 'Found ' . @commits . ' Rakudo commits to add';
    $model_com->add(@commits);

    1;
}

sub fetch_tickets_gist {
    my ($rt, $model_rt, $model_var, $is_rebuild) = @_;
    # Save fetch date before starting the request, so we don't lose stuff if
    # the requests fails

    my $last_fetch_date = $model_var->var('db_tickets_gist_last_updated') // 0;
    $last_fetch_date = strftime '%Y-%m-%d', localtime $last_fetch_date
        if $last_fetch_date;

    say "Fetching tickets updated since $last_fetch_date";
    my $fetch_date = time;

    # If we are rebuilding from scratch, fetch only tickets with wanted
    # statuses. If we are NOT rebuilding from scratch, fetch changed tickets
    # with ALL statuses, and delete those with unwanted statuses from the
    # database.
    if ( $is_rebuild ) {
        my @tickets = $rt->search;
        say 'Found ' . @tickets . ' tickets';
        return unless @tickets; # 0 tickets usually indicates an error
        $model_rt->add(\@tickets, all_reviewed => 1);
    }
    else {
        my @all_tickets = $rt->search(
            status     => undef,
            not_status => undef,
            ($last_fetch_date ? ( updated_after => $last_fetch_date ) : ()),
        );
        say 'Found ' . @all_tickets . ' total tickets';
        return unless @all_tickets; # don't do stuff if we have 0 tickets; may be an error
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

    $model_var->save( db_tickets_gist_last_updated => $fetch_date );
}

__END__


