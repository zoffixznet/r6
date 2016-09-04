package R6::Model::Schema::Result::RakudoCommits;
use     R6::Model::ResultClass;

primary_column sha      => { data_type => 'text' };
column         url      => { data_type => 'text' };
column         message  => { data_type => 'text' };
column         author   => { data_type => 'text' };
column         date     => { data_type => 'int'  };
column         is_added => { data_type => 'bool', default_value => 0 };

1;

__END__