package R6::Model::Schema::Result::Var;
use     R6::Model::ResultClass;

primary_column name  => { data_type => 'text' };
column         value => { data_type => 'text' };

1;

__END__
