use strict;
use warnings;
use 5.024;
use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use File::Spec::Functions qw/catfile/;
use R6::Model::RT;
use R6::RT::Client::REST::Lazy;

my $conf = do "$FindBin::Bin/../R6.conf" or die 'Failed to load R6.conf';
# my $rt = R6::RT::Client::REST::Lazy->new(
#     login => $conf->{rt}{login},
#     pass  => $conf->{rt}{pass},
# );
my $model = R6::Model::RT->new;

# my @tickets = $rt->search( after => '2016-08-20' );
my @tickets = (
  {
    'tags' => [
                'RFC'
              ],
    'id' => '129025',
    'subject' => '[RFC] Warn the user if there is any code in a given block after the default or a when { * }'
  },
  {
    'id' => '129023',
    'subject' => '[RFC] can\'t coerce to role by calling',
    'tags' => [
                'RFC'
              ]
  },
  {
    'tags' => [
                'JVM'
              ],
    'subject' => '[JVM] REPL does not work anymore: \'ContextRef representation does not implement elems\'',
    'id' => '129020'
  },
  {
    'subject' => '[BUG] Range.WHICH fails on many kinds of endpoints',
    'id' => '129019',
    'tags' => [
                'BUG'
              ]
  },
  {
    'subject' => '[BUG] Range.perl doesn\'t round-trip Range endpoints',
    'id' => '129018',
    'tags' => [
                'BUG'
              ]
  },
  {
    'subject' => '[BUG] Range.perl doesn\'t round-trip Junction endpoints',
    'id' => '129017',
    'tags' => [
                'BUG'
              ]
  },
  {
    'tags' => [
                'BUG'
              ],
    'id' => '129015',
    'subject' => '[BUG] Set.perl doesn\'t round-trip iterables'
  },
  {
    'tags' => [
                'BUG'
              ],
    'id' => '129014',
    'subject' => '[BUG] Range.new confused by type objects'
  },
  {
    'tags' => [
                'BUG'
              ],
    'id' => '129013',
    'subject' => '[BUG] Range.perl and Pair.perl precedence disagreement'
  }
);
say 'Found ' . @tickets . ' tickets';
$model->add(@tickets);


