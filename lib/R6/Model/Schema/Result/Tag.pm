package R6::Model::Schema::Result::Tag;
# use     R6::Model::ResultClass;
use strictures 2;

use base 'DBIx::Class::Core';
__PACKAGE__->table('tag');
__PACKAGE__->add_columns(  id => {
    data_type => 'integer',
    is_auto_increment => 1,
  }, qw/tag/);
__PACKAGE__->set_primary_key('id');
# __PACKAGE__->has_many('ticket_tag' => 'R6::Model::RT::Schema::Result::TicketTag', 'tag');
# __PACKAGE__->many_to_many('tickets' => 'ticket_tag', 'ticket');

#primary_column tag_id => { data_type => 'int'  };
# column         tag    => { data_type => 'text' };

# has_many ticket_tag
#     => 'R6::Model::Schema::Result::TicketTag' => 'tag';
# many_to_many tickets => 'ticket_tag' => 'ticket';

1;

__END__