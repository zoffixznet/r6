#!/bin/bash
source /home/zoffix/.bashrc
source /home/zoffix/perl5/perlbrew/etc/bashrc
set -e
set -x
cd /var/www/perl6.fail/
perl bin/db-builder.pl
