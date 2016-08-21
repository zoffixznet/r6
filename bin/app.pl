#!perl

# VERSION

use Mojolicious::Lite;
use 5.024;
use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

require Mojolicious::Commands;
Mojolicious::Commands->start_app('R6');

__END__
