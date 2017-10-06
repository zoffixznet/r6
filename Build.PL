use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name        => 'R6',
    dist_abstract      => 'R6',
    dist_name          => 'fail.rakudo.party',
    dist_author        => 'R6',
    license            => 'perl',
    create_makefile_pl => 'passthrough',
    dist_version => '0.1',
    recursive_test_files => 1,
    requires => {
      'Date::Manip'     => '6.60',
      'IO::Socket::IP'  => '0.37',  # required to fix an issue with SSL in Mojo
      'IO::Socket::SSL' => '2.020', # Mojo::UserAgent
    }
);
$build->create_build_script;
