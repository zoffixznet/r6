package R6::Model::RT::Schema::Result::Ticket;
use     R6::Model::ResultClass;

primary_column ticket_id     => { data_type => 'int' };
column         subject       => { data_type => 'text' };

has_many tags
    => 'R6::Model::RT::Schema::Result::Tag' => 'tag_id';

1;

__END__