#!/usr/bin/perl -w
#$rcs = ' $Id: pwrbar,v 1.0 2004/03/30 00:00:00 Exp $ ' ;

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
#   use CGI::Carp qw(carpout);
#   open (ERRORLOG, ">>/home/grepinco/public_html/cgi-bin/log/pwrbarerrlog.txt")
#       or die "Unable to append to errorlog: $!\n";
#   carpout(*ERRORLOG);
}

# Grepin Search and Services
# Copyright (C) 2004 Grepin Search and Services <contact@grepin.com>

# Comment in the next two lines to log and show how long searches take:
use Time::HiRes qw ();
my $start_time = [Time::HiRes::gettimeofday];

$|=1;    # autoflush

use CGI;
use Fcntl;
use POSIX qw(strftime);

# added program path to @INC because it fails to find ./conf.pl if started from
# other directory
{ 
  # block is for $1 not mantaining its value
  $0 =~ /(.*)(\\|\/)/;
  push @INC, $1 if $1;
}

my $db_package = "";
# To use tainting, comment in the next 2 lines and comment out the next 8 lines.
# Note that you also have to add "./" to the filenames in the require commands.
#use DB_File;
#$db_package = 'DB_File';
package AnyDBM_File;
@ISA = qw(DB_File);
# You may try to comment in the next line if you don't have DB_File. Still
# this is not recommended.
#@ISA = qw(DB_File GDBM_File SDBM_File ODBM_File NDBM_File);
foreach my $isa (@ISA) {
  if( eval("require $isa") ) {
    $db_package = $isa;
    last;
  }
}

package main;

my $query;
$query = new CGI;

my $user_id = $query->param('uid');

print "Content-Type: text/html\n\n";

if (!$user_id){

# show an advertizement about power-list...

  print "<br />Note: The parameter uid is either invalid or empty.\n";
  print "<br />      Please give the correct uid and try again.\n";
  print "<br />      Or please inform the webmaster about this error.\n";
  exit;
}

my $MAIN_DIR          = '/home/grepinco/public_html/cgi-bin/';
my $SEARCH_URL        = '/cgi-bin/pwrbar';
my $USER_LOCAL_DIR    = $MAIN_DIR.$user_id.'/';
my $INSTALL_DIR       = $USER_LOCAL_DIR.'search/';
my $DATA_DIR          = $INSTALL_DIR.'/data/';
my $LOGDIR            = $INSTALL_DIR.'/log/';
my $TEMPLATE_DIR      = $INSTALL_DIR.'/templates/';

my $PWRLST_DB_FILE           = $USER_DIR.'pwrlst';

my $PROD_USER_DIR            = $USER_LOCAL_DIR.'products/';
my $PROD_PROF_DB_FILE        = $PROD_USER_DIR.'profile';
my $PROD_THEME_DB_FILE       = $PROD_USER_DIR.'theme';
my $KEYWORD_DB_FILE          = $PROD_USER_DIR.'keyword';

my $yday = (localtime time())[7];
my $LOGFILE   = $LOGDIR.'pwrbarlog'.$yday;
my $ERRORFILE = $LOGDIR.'errorlog';

my %prod_prof_dbfile;
my %keyword_dbfile;
my %theme_dbfile;

eval {
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    tie %theme_dbfile, "DB_File", $PROD_THEME_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_THEME_DB_FILE: $!";
    tie %keyword_dbfile, "DB_File", $KEYWORD_DB_FILE, O_RDONLY, 0755 or die "Cannot open $KEYWORD_DB_FILE: $!";
};
if ($@) {
  print "<br />Note: The power-list is not yet created for this account.\n";
  print "<br />      Please inform the webmaster about this error.\n";
  exit;
}  

my ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10);

get_bar();

exit;

sub get_bar {

  my $pl        = $query->param('pl');   # promotion list name

  my $keyword   = $query->param('k');  # keywords

  my $prod_in1  = $query->param('pr1');  # user specified product
  my $prod_in2  = $query->param('pr2');  # user specified product
  my $prod_in3  = $query->param('pr3');  # user specified product
  my $prod_in4  = $query->param('pr4');  # user specified product
  my $prod_in5  = $query->param('pr5');  # user specified product

  my $type      = $query->param('t');    # type of the box 0 to 7
  my $caption   = $query->param('c');    # caption for the box - default 'featured'
  my $disp      = $query->param('d');    # how many products to display? maximum of 5 and minimum of 1
  my $size      = $query->param('s');    # size of the box - s-small, m-medium, l-large
  my $look      = $query->param('l');    # look of the box - 0-classic, 1-green, 2-blue, 
  my $target    = $query->param('win');  # open in which window? n-new or ' '-same
  my $affiliate = $query->param('aff');  # display affiliate link? y-yes, n-no
  my $text      = $query->param('r');    # replacement text
  my $text1     = $query->param('r1');   # replacement text1
  my $text2     = $query->param('r2');   # replacement text2
  my $text3     = $query->param('r3');   # replacement text3
  my $text4     = $query->param('r4');   # replacement text4
  my $text5     = $query->param('r5');   # replacement text5
  my $text6     = $query->param('r6');   # replacement text6
  my $text7     = $query->param('r7');   # replacement text7
  my $text8     = $query->param('r8');   # replacement text8
  my $text9     = $query->param('r9');   # replacement text9
  my $source    = $query->param('src');  # source
  my $search    = $query->param('search');  # is it from search engine script? 'y'=yes

  my $prod_found = 0;
  my ($i, $j, $k);
  my $prod_num  = 0;

  my @products  = ();
  my @title     = ();
  my @desc      = ();
  my @image_url = ();
  my @dest_url  = ();
  my @prod_array = ();


  if ($keyword) {
    if ($keyword_dbfile{$keyword}) {
      @products = $keyword_dbfile{$keyword};
      $prod_found = 1;
    } else {
      log in the log file with "no products available for this keyword - $keyword"
    }
  }

  if ($prod_found == 0) {
    foreach (keys %theme_dbfile) {
      push @products, $_;
    }
    if (@products == 0) {
      log in the error file with "no theme products available"
      return (1,"List is empty.");
    }
  }

  $prod_num = @products;

  if ($disp > $prod_num) {
    $i = 1;
    $j = $prod_num;
  } else {
    $i = rand();
    $i = int($prod_num * rand()) + 1; # starting position in the products array
    $j = $i + $disp;                  # ending position in the products array
  }

  @products = (@products, @products);

  $k = 0;
  for ($i..$j) {
    $k++;
    push @prod_array, @products($_);
    ($title[$k], $desc[$k], $image_url[$k], $dest_url[$k], $d5, $d6, $d7, $d8, $d9, $d10, $d11) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{@products($_)});
  }

  format the results in bar

  print $list_html;

  $prod_list = join(@prod_array, ':::')
  log_query ($disp, $prod_list);


WHILE DISPLAYING WE SHOULD USE THE TRACK-CODE (ADD THIS IN PWRBAR) AND LOG IT
THIS WILL MAKE IT POSSIBLE TO SAY THAT THIS PARTICULAR DISPLAY HAD GOT THE CLICK

TRACK-CODE CAN BE A TIMESTAMP ALONG WITH SOMETHING ELSE TO MAKE IT UNIQUE


}





# Log the query in a file, using this format:
# REMOTE_HOST;date;terms;matches;current page;(time to search in seconds);
# For the last value you need to use Time::HiRes (see top of the script)
sub log_query {

  my $disp      = shift;
  my $prod_list = shift;

  my $elapsed_time = sprintf("%.2f", Time::HiRes::tv_interval($start_time)) if( $start_time );
  my @line = ();
  my $addr = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'};
  push(@line, time(),
              $disp || '0',
              $prod_list || '-',
              $addr || '-',
              $query->param('pl') || '-',
              $query->param('k') || '-',
              $query->param('pr1') || '-',
              $query->param('pr2') || '-',
              $query->param('pr3') || '-',
              $query->param('pr4') || '-',
              $query->param('pr5') || '-',
              $query->param('t') || '-',
              $query->param('c') || '-',
              $query->param('d') || '-',
              $query->param('s') || '-',
              $query->param('l') || '-',
              $query->param('win') || '-',
              $query->param('aff') || '-',
              $query->param('r') || '-',
              $query->param('r1') || '-',
              $query->param('r2') || '-',
              $query->param('r3') || '-',
              $query->param('r4') || '-',
              $query->param('r5') || '-',
              $query->param('r6') || '-',
              $query->param('r7') || '-',
              $query->param('r8') || '-',
              $query->param('r9') || '-',
              $query->param('src') || '-',
              $query->param('search') || '-');

  use Fcntl ':flock';        # import LOCK_* constants
  open(LOG, ">>$LOGFILE") or die "Cannot open logfile '$LOGFILE' for writing: $!";
  flock(LOG, LOCK_EX);
  seek(LOG, 0, 2);
  print LOG join(':::', @line).":::\n";
  flock(LOG, LOCK_UN);
  close(LOG);
}

# Log the error in a file, using this format:
# REMOTE_HOST;date;terms;
# For the last value you need to use Time::HiRes (see top of the script)
sub log_error {

  my $process = shift;
  my $message = shift;
  my @line = ();
  my $addr = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'};
  push(@line, time(),
              $process || '-',
              $message || '-',
              $addr || '-');
              $query->param('pl') || '-',
              $query->param('k') || '-',
              $query->param('t') || '-',
              $query->param('c') || '-',
              $query->param('d') || '-',
              $query->param('s') || '-',
              $query->param('l') || '-',
              $query->param('win') || '-',
              $query->param('aff') || '-',
              $query->param('r') || '-',
              $query->param('r1') || '-',
              $query->param('r2') || '-',
              $query->param('r3') || '-',
              $query->param('r4') || '-',
              $query->param('r5') || '-',
              $query->param('r6') || '-',
              $query->param('r7') || '-',
              $query->param('r8') || '-',
              $query->param('r9') || '-',
              $query->param('src') || '-',
              $query->param('search') || '-');

  use Fcntl ':flock';        # import LOCK_* constants
  open(ERRLOG, ">>$ERRORFILE") or die "Cannot open errorfile '$ERRORFILE' for writing: $!";
  flock(ERRLOG, LOCK_EX);
  seek(ERRLOG, 0, 2);
  print ERRLOG join(':::', @line).":::\n";
  flock(ERRLOG, LOCK_UN);
  close(ERRLOG);
}

sub debug {
	my $str = shift;
	if( $HTTP_DEBUG && $ENV{'REQUEST_METHOD'} ) {
		print $str;
	} elsif( $HTTP_DEBUG && ! $ENV{'REQUEST_METHOD'} ) {
		print STDERR $str;
	}
}

sub error {
	my $str = shift;
	if( $ENV{'REQUEST_METHOD'} ) {
		print $str;
	} else {
		print STDERR $str;
	}
}
