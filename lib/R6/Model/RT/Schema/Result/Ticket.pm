package R6::Model::RT::Schema::Result::Ticket;
# use     R6::Model::ResultClass;
use strictures 2;

use base 'DBIx::Class::Core';
__PACKAGE__->table('ticket');
__PACKAGE__->add_columns(
  id => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  qw/subject/
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many('ticket_tag' => 'R6::Model::RT::Schema::Result::TicketTag', 'ticket');
__PACKAGE__->many_to_many('tags' => 'ticket_tag', 'tag');


#primary_column ticket_id     => { data_type => 'int'  };
# column         subject       => { data_type => 'text' };

# has_many ticket_tag
#     => 'R6::Model::RT::Schema::Result::TicketTag' => 'ticket';
# many_to_many tags => 'ticket_tag' => 'tag';

1;

__END__