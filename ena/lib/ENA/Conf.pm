package ENA::Conf;

use strict;
use warnings;

use FindBin qw($Bin $Script);
use lib "$Bin/../lib";
our $db_dir    = "$Bin/../../dict/db";
our $gdbm_dir  = "$Bin/../../dict/gdbm";
our $tools_dir = "$Bin/../tools";
our $mod_dir   = "$Bin/../dat/mod";

$ENV{ZERO_PATH}     = '/home/mamoru-k/toyota';
$ENV{ZERO_DAT_PATH} = '/work/ryu-i/jsa/dat';
$ENV{ENA_DB_DIR}    = $db_dir;
$ENV{ENA_GDBM_DIR}  = $gdbm_dir;
$ENV{ENA_TOOLS_DIR} = $tools_dir;
$ENV{ENA_MOD_DIR}   = $mod_dir;

1;
