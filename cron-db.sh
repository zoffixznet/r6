#!/bin/bash
source /home/zoffix/.bashrc
set -e
set -x
cd /var/www/perl6.fail/
perl bin/db-builder.pl
