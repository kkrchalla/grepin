#!/usr/bin/perl -w
#$rcs = ' $Id: credbfls.pl,v 1.00 2004/08/12 22:45:42 Grepin Exp $ ' ;

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
}

# Grepin Search and Services
#

use Fcntl;

$|=1;    # autoflush

print "Content-Type: text/html\n\n";
my $title = "Creation of all the database files";
print "<html><head><title>$title</title></head><body>";
print "<h2>$title</h2>\n\n";
print "<pre>";
use CGI;

{ 
  # block is for $1 not mantaining its value
  $0 =~ /(.*)(\\|\/)/;
  push @INC, $1 if $1;
}

my $db_package = "";
package AnyDBM_File;
@ISA = qw(DB_File);
foreach my $isa (@ISA) {
  if( eval("require $isa") ) {
    $db_package = $isa;
    last;
  }
}
if( $db_package  ne 'DB_File' ) {
  die "*** The DB_File module was not found on your system.";
}

package main;

  my $query = new CGI;

  my $MAIN_DIR = '/home/grepinco/public_html/cgi-bin/';
  my $LOG_DIR  = $MAIN_DIR.'log/';
  my $PAGE_DIR = $MAIN_DIR.'pages/';
  my $SRCH_DIR = $MAIN_DIR.'search/';
  my $TMPL_DIR = $MAIN_DIR.'templates/';
  my $USER_DIR = $MAIN_DIR.'users/';
  my $UTIL_DIR = $MAIN_DIR.'utility/';

  my $SRCH_COMN_DIR = $SRCH_DIR.'common/';
  my $SRCH_RPRT_DIR = $SRCH_DIR.'reports/';
  my $SRCH_USER_DIR = $SRCH_DIR.'users/';



  my $LATEST_IDS_DB_FILE         = $USER_DIR.'latestids';
  my $SESSION_DB_FILE            = $USER_DIR.'session';
  my $USER_PWD_DB_FILE           = $USER_DIR.'userpwd';
  my $USER_PROFILE_DB_FILE       = $USER_DIR.'userprof';
  my $USER_INDEX_DATA_DB_FILE    = $USER_DIR.'userindxdata';
  my $USER_TEMPLATE_DATA_DB_FILE = $USER_DIR.'usertmpldata';
  my $USER_STATUS_DB_FILE        = $USER_DIR.'userstatus';
  my $JOB_STATUS_DB_FILE         = $USER_DIR.'jobstatus';
  my $QUEUE_DB_FILE              = $USER_DIR.'queue';
  my $INDEX_QUEUE_DB_FILE        = $USER_DIR.'indxqueue';
  my $REPORT_QUEUE_DB_FILE       = $USER_DIR.'rprtqueue';
  my $SEARCHLOG_DB_FILE          = $USER_DIR.'srchlog';
  my $NOMATCHLOG_DB_FILE         = $USER_DIR.'nomatchlog';
  my $AMZN_RSLT_DB_FILE          = $USER_DIR.'amznrslt';

  my $AFF_PWD_DB_FILE       = $USER_DIR.'affpwd';
  my $AFF_PROFILE_DB_FILE   = $USER_DIR.'affprof';
  my $AFF_USER_DB_FILE      = $USER_DIR.'affuser';
  my $USER_AFF_DB_FILE      = $USER_DIR.'useraff';
  my $TOP_BAR_HTML_DB_FILE  = $USER_DIR.'topbarhtml';
  my $BOT_BAR_HTML_DB_FILE  = $USER_DIR.'botbarhtml';
  my $LEFT_BAR_HTML_DB_FILE = $USER_DIR.'leftbarhtml';

print "   Using $db_package...\n";

  create_db($LATEST_IDS_DB_FILE); 
  create_db($SESSION_DB_FILE); 
  create_db($USER_PWD_DB_FILE); 
  create_db($USER_PROFILE_DB_FILE); 
  create_db($USER_INDEX_DATA_DB_FILE); 
  create_db($USER_TEMPLATE_DATA_DB_FILE); 
  create_db($USER_STATUS_DB_FILE); 
  create_db($JOB_STATUS_DB_FILE); 
  create_db($QUEUE_DB_FILE); 
  create_db($INDEX_QUEUE_DB_FILE); 
  create_db($REPORT_QUEUE_DB_FILE); 
  create_db($SEARCHLOG_DB_FILE); 
  create_db($NOMATCHLOG_DB_FILE); 
  create_db($AMZN_RSLT_DB_FILE); 

  create_db($AFF_PWD_DB_FILE);
  create_db($AFF_PROFILE_DB_FILE);
  create_db($AFF_USER_DB_FILE);
  create_db($USER_AFF_DB_FILE);
  create_db($TOP_BAR_HTML_DB_FILE);
  create_db($BOT_BAR_HTML_DB_FILE);
  create_db($LEFT_BAR_HTML_DB_FILE);

print "   Creating dbfiles done.\n";
exit;

# Copy the keys and values of a hash to a persistent file on disk.
sub create_db {
  my $name = shift;
  print " creating db file - $name\n";
  my %db_tmp;
  $db_tmp{"a"} = "a"; 
  tie %db_tmp, "DB_File", $name, O_CREAT|O_RDWR, 0755 or die "Cannot create '$name': $!"; 
  untie %db_tmp;
}

1;