#!/usr/bin/perl -w
#$rcs = ' $Id: ftrack,v 1.0 2004/03/30 00:00:00 Exp $ ' ;

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
#   use CGI::Carp qw(carpout);
#   open (ERRORLOG, ">>/home/grepinco/public_html/cgi-bin/log/ftrackerrlog.txt")
#       or die "Unable to append to errorlog: $!\n";
#   carpout(*ERRORLOG);
}

# Grepin Search and Services
# Copyright (C) 2004 Grepin Search and Services <contact@grepin.com>



usage - www.grepin.com/cgi-bin/ftrack?uid=u1000nn&kwd=<converted kwd>&src=<converted src>&url=<converted url>&prd=xxxxx
	&t=x&c=x&d=x&s=x&l=x&tpl=xx
uid
kwd
src
url
t
s
l
c
d
prd
tpl (template)


log the incident that the image was clicked and so and so options were used for the box....
this will give the user where the link was clicked, and what type of options were used for this click..
and he can change the looks and feel to get the most and stick with the best click stuff..

this data can be used to present to him under the section - "what works and what doesn't"


WHILE DISPLAYING WE SHOULD USE THE TRACK-CODE (ADD THIS IN PWRBAR)
THEN HERE WE SHOULD LOG THE TRACK-CODE
THIS WILL MAKE IT POSSIBLE TO SAY THAT THIS PARTICULAR DISPLAY HAD GOT THE CLICK

TRACK-CODE CAN BE A TIMESTAMP ALONG WITH SOMETHING ELSE TO MAKE IT UNIQUE




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
  print "<br />Note: The parameter uid is either invalid or empty.\n";
  print "<br />      Please give the correct uid and try again.\n";
  print "<br />      Or please inform the webmaster about this error.\n";
  exit;
}

my $MAIN_DIR          = '/home/grepinco/public_html/cgi-bin/';
my $SEARCH_URL        = '/cgi-bin/ftrack';
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
my $LOGFILE   = $LOGDIR.'ftracklog'.$yday;
my $ERRORFILE = $LOGDIR.'errorlog';

# See indexer.pl for a description of the data structures:
my %prod_prof_dbfile;
my %keyword_dbfile;
my %theme_dbfile;

eval {
    tie %prod_prof_dbfile, "DB_File", $PROD_PROF_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_PROF_DB_FILE: $!";
    tie %theme_dbfile, "DB_File", $PROD_THEME_DB_FILE, O_RDONLY, 0755 or die "Cannot open $PROD_THEME_DB_FILE: $!";
    tie %keyword_dbfile, "DB_File", $KEYWORD_DB_FILE, O_RDONLY, 0755 or die "Cannot open $KEYWORD_DB_FILE: $!";
};
if ($@) {
  print "<br />Note: This web site is not yet indexed for search.\n";
  print "<br />      Please inform the webmaster about this error.\n";
  exit;
}  

my ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10);

main();

exit;

sub main {
  # ?uid=xxx&kwd=xxx&t=0&c=featured&d=3&s=m&l=0&win=n&aff=y&r=a100001&src=page1

  my $keyword   = $query->param('kwd');
  my $type      = $query->param('t');    # type of the box 0 to 7
  my $caption   = $query->param('c');    # title for the box - default 'featured'
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

  my @products  = ();
  my @title     = ();
  my @desc      = ();
  my @image_url = ();
  my @dest_url  = ();

  edits for all fields and change the invalid data to default data....

  if ($keyword && $keyword_dbfile{$keyword}) {
    @products = $keyword_dbfile{$keyword};
  } else {
    log in the log file with "no products available for this keyword - $keyword"
    foreach (keys %theme_dbfile) {
      push @products, $_;
    }
    if (@products == 0) {
      log in the error file with "no theme products available"
      exit;
    }
  }

  $prod_num = @products;

  if ($disp > $prod_num) {
    $disp = $prod_num;
  }

  get the next number of products to be displayed...
  $i == next number of product
  $j = $i + $disp; # last number of products

  @products = (@products, @products);

  $k = 0;
  for ($i..$j) {
    $k++;
    push @prod_array, $_;
    ($title[$k], $desc[$k], $image_url[$k], $dest_url[$k], $d5, $d6, $d7, $d8, $d9, $d10, $d11) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $prod_prof_dbfile{$_});
  }

  format the results

  print $list_html;

  $prod_list = join(@prod_array, ':::')
  log_query ($disp, $prod_list);

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
  push(@line, $query->param('kwd') || '-',
              time(),
              $disp || '0',
              $prod_list || '-',
              $query->param('source') || '-',
              $addr || '-');

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
  push(@line, $process || '-',
              $message || '-',
              $query->param('q') || '-',
              get_iso_date(),
              $addr || '-');

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
