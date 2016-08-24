package R6::Model::RT::Schema::Result::TicketTag;
# use     R6::Model::ResultClass;
use strictures 2;

use base 'DBIx::Class::Core';
__PACKAGE__->table('ticket_tag');
__PACKAGE__->add_columns(qw/ticket tag/);
__PACKAGE__->set_primary_key(qw/ticket tag/);
__PACKAGE__->belongs_to('ticket' => 'R6::Model::RT::Schema::Result::Ticket');
__PACKAGE__->belongs_to('tag' => 'R6::Model::RT::Schema::Result::Tag');

#column       ticket => { data_type => 'int' };
# column       tag    => { data_type => 'int' };
# primary_key  qw/ticket  tag/;

# belongs_to ticket => 'R6::Model::RT::Schema::Result::Ticket';
# belongs_to tag    => 'R6::Model::RT::Schema::Result::Tag';

1;

__END__




