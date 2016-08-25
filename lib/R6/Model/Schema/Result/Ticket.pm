package R6::Model::Schema::Result::Ticket;
use     R6::Model::ResultClass;

primary_column ticket_id     => { data_type => 'int'  };
column         subject       => { data_type => 'text' };
column         tags          => { data_type => 'text' };
column         created       => { data_type => 'text' };
column         lastupdated   => { data_type => 'text' };
column         creator       => { data_type => 'text' };
column         is_reviewed   => { data_type => 'bool', default_value => 0 };
column         is_blocker    => { data_type => 'bool', default_value => 0 };

# has_many ticket_tag
#     => 'R6::Model::Schema::Result::TicketTag' => 'ticket';
# many_to_many tags => 'ticket_tag' => 'tag';

1;

__END__