#!/usr/bin/perl
#$rcs = ' $Id: implementation.pl,v 1.00 2004/08/12 22:45:42 Grepin Exp $ ' ;

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
}

# Grepin Search and Services
#

use Fcntl;

$|=1;    # autoflush

print "Content-Type: text/html\n\n";
my $title = "Implementation of Grepin 1.0";
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

    mkdir $LOG_DIR, 0755, or die "Cannot create log directory '$LOG_DIR': $!";
    mkdir $PAGE_DIR, 0755, or die "Cannot create page directory '$PAGE_DIR': $!";
    mkdir $SRCH_DIR, 0755, or die "Cannot create search directory '$SRCH_DIR': $!";
    mkdir $TMPL_DIR, 0755, or die "Cannot create template directory '$TMPL_DIR': $!";
    mkdir $USER_DIR, 0755, or die "Cannot create user directory '$USER_DIR': $!";
    mkdir $UTIL_DIR, 0755, or die "Cannot create utility directory '$UTIL_DIR': $!";
    mkdir $SRCH_COMN_DIR, 0755, or die "Cannot create search common directory '$SRCH_COMN_DIR': $!";
    mkdir $SRCH_RPRT_DIR, 0755, or die "Cannot create search report directory '$SRCH_RPRT_DIR': $!";
    mkdir $SRCH_USER_DIR, 0755, or die "Cannot create search user directory '$SRCH_USER_DIR': $!";


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

print "   Implementation done.\n";
exit;

# Copy the keys and values of a hash to a persistent file on disk.
sub create_db {
  my $name = shift;
  print " creating db file - $name\n";
  my %db_tmp;
  tie %db_tmp, "DB_File", $name, O_CREAT, 0755 or die "Cannot create '$name': $!"; 
  untie %db_tmp;
}

1;