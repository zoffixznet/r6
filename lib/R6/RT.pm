package R6::RT;

use 5.024;
use Mew;
use RT::Client::REST::Lazy;
use Acme::Dump::And::Dumper;

has [qw/_login  _pass/] => Str;
has _rt => ( is => 'lazy',
    default => sub {
        my $self = shift;
        RT::Client::REST::Lazy->new(
            login   => $self->_login,
            pass    => $self->_pass,
        );
    }
);

sub show_ticket {
    my ( $self, $ticket_id ) = @_;
    my @trans = $self->_rt->get_transaction_ids( parent_id => $ticket_id );
    print Dumper \@trans;
    for my $id ( @trans ) {
        my $t = $self->_rt->get_transaction(
            parent_id => $ticket_id, id => $id
        );
        say "Transaction $id";
        print Dumper $t;
    }
}

sub search {
    my $self = shift;
    say 'Starting search';
    my @ids = $self->_rt->search(
        orderby => '-id',
        type    => 'ticket',
        query   => (
            join ' AND ', "Queue = 'perl6'",
                map "Status != '$_'", qw/stalled resolved  rejected/,
        )
    );
    say 'Done with the search';

    for my $id (@ids) {
        my ( $ticket ) = $self->_rt->show( type => 'ticket', id => $id );
        print Dumper $ticket;
        print "Subject: ", $ticket->{Subject}, "\n";
    }
}


# try {
#     # Get ticket #10
#   $ticket = $rt->show(type => 'ticket', id => 10);
# } catch RT::Client::REST::UnauthorizedActionException with {
#   print "You are not authorized to view ticket #10\n";
# } catch RT::Client::REST::Exception with {
#   # something went wrong.
# };

1;

__END__
