package R6::Model::RT::Schema::Result::Ticket;
use     R6::Model::ResultClass;

primary_column ticket_id     => { data_type => 'int'  };
column         subject       => { data_type => 'text' };
column         tags          => { data_type => 'text' };

# has_many ticket_tag
#     => 'R6::Model::RT::Schema::Result::TicketTag' => 'ticket';
# many_to_many tags => 'ticket_tag' => 'tag';

1;

__END__