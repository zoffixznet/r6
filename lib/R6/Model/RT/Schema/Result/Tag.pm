package R6::Model::RT::Schema::Result::Tag;
use     R6::Model::ResultClass;

primary_column tag_id => { data_type => 'int' };
column         tag    => { data_type => 'text' };

has_many tickets
    => 'R6::Model::RT::Schema::Result::Ticket' => 'ticket_id';

1;

__END__