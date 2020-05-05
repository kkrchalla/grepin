#!/usr/bin/perl
#$rcs = ' $Id: dbfiles_create.pl,v 1.00 2004/08/12 22:45:42 Grepin Exp $ ' ;

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
}

# Grepin Search and Services
#

use Fcntl;

$|=1;    # autoflush

print "Content-Type: text/html\n\n";
my $title = "Create DB Files";
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
my $uid = $query->param('uid');

my $LATEST_IDS_DB_FILE         = '/home/grepinco/public_html/cgi-bin/users/latestids';
my $SESSION_DB_FILE            = '/home/grepinco/public_html/cgi-bin/users/session';
my $USER_PWD_DB_FILE           = '/home/grepinco/public_html/cgi-bin/users/userpwd';
my $USER_PROFILE_DB_FILE       = '/home/grepinco/public_html/cgi-bin/users/userprof';
my $USER_INDEX_DATA_DB_FILE    = '/home/grepinco/public_html/cgi-bin/users/userindxdata';
my $USER_TEMPLATE_DATA_DB_FILE = '/home/grepinco/public_html/cgi-bin/users/usertmpldata';
my $JOB_STATUS_DB_FILE         = '/home/grepinco/public_html/cgi-bin/users/jobstatus';
my $QUEUE_DB_FILE              = '/home/grepinco/public_html/cgi-bin/users/queue';
my $INDEX_QUEUE_DB_FILE        = '/home/grepinco/public_html/cgi-bin/users/indxqueue';
my $REPORT_QUEUE_DB_FILE       = '/home/grepinco/public_html/cgi-bin/users/rprtqueue';
my $SEARCHLOG_MONTH_DB_FILE    = '/home/grepinco/public_html/cgi-bin/users/srchlogmth';
my $NOMATCHLOG_MONTH_DB_FILE   = '/home/grepinco/public_html/cgi-bin/users/nomatchmth';
my $SEARCHLOG_DB_FILE          = '/home/grepinco/public_html/cgi-bin/users/srchlog';
my $NOMATCHLOG_DB_FILE         = '/home/grepinco/public_html/cgi-bin/users/nomatchlog';

  my $AFF_PWD_DB_FILE       = '/home/grepinco/public_html/cgi-bin/users/affpwd';
  my $AFF_PROFILE_DB_FILE   = '/home/grepinco/public_html/cgi-bin/users/affprof';
  my $AFF_USER_DB_FILE      = '/home/grepinco/public_html/cgi-bin/users/affuser';
  my $USER_AFF_DB_FILE      = '/home/grepinco/public_html/cgi-bin/users/useraff';
  my $TOP_BAR_HTML_DB_FILE  = '/home/grepinco/public_html/cgi-bin/users/topbarhtml';
  my $BOT_BAR_HTML_DB_FILE  = '/home/grepinco/public_html/cgi-bin/users/botbarhtml';
  my $LEFT_BAR_HTML_DB_FILE = '/home/grepinco/public_html/cgi-bin/users/leftbarhtml';
  my $AMZN_RSLT_DB_FILE     = '/home/grepinco/public_html/cgi-bin/users/amznrslt';

print "Using $db_package...\n";

  my %a_db;
  my %b_db;
  my %c_db;
  my %d_db;
  my %e_db;
  my %f_db;
  my %g_db;
  my %h_db;
  my %i_db;
  my %j_db;
  my %k_db;
  my %l_db;
  my %m_db;
  my %n_db;

  $a_db{"dummy"} = "dummy"; 
  $b_db{"dummy"} = "dummy"; 
  $c_db{"dummy"} = "dummy"; 
  $d_db{"dummy"} = "dummy"; 
  $e_db{"dummy"} = "dummy"; 
  $f_db{"dummy"} = "dummy"; 
  $g_db{"dummy"} = "dummy"; 
  $h_db{"dummy"} = "dummy"; 
  $i_db{"dummy"} = "dummy"; 
  $j_db{"dummy"} = "dummy"; 
  $k_db{"dummy"} = "dummy"; 
  $l_db{"dummy"} = "dummy"; 
  $m_db{"dummy"} = "dummy"; 
  $n_db{"dummy"} = "dummy"; 

  print "Copying hash values to database files...\n"; 
  save_db($AMZN_RSLT_DB_FILE, %n_db); 
#  save_db($AFF_PWD_DB_FILE, %n_db); 
#  save_db($AFF_PROFILE_DB_FILE  , %a_db);
#  save_db($AFF_USER_DB_FILE     , %b_db);
#  save_db($USER_AFF_DB_FILE     , %c_db);
#  save_db($TOP_BAR_HTML_DB_FILE , %d_db);
#  save_db($BOT_BAR_HTML_DB_FILE , %e_db);
#  save_db($LEFT_BAR_HTML_DB_FILE, %f_db);


#  save_db($USER_PWD_DB_FILE, %a_db); 
#  save_db($USER_PROFILE_DB_FILE, %b_db); 
#  save_db($USER_INDEX_DATA_DB_FILE, %c_db); 
#  save_db($LATEST_IDS_DB_FILE, %d_db); 
#  save_db($SESSION_DB_FILE, %e_db); 
#  save_db($USER_TEMPLATE_DATA_DB_FILE, %f_db); 
#  save_db($JOB_STATUS_DB_FILE, %g_db); 
#  save_db($QUEUE_DB_FILE, %h_db); 
#  save_db($INDEX_QUEUE_DB_FILE, %i_db); 
#  save_db($REPORT_QUEUE_DB_FILE, %j_db); 
#  save_db($SEARCHLOG_MONTH_DB_FILE, %k_db); 
#  save_db($SEARCHLOG_DB_FILE, %l_db); 
#  save_db($NOMATCHLOG_MONTH_DB_FILE, %m_db); 
#  save_db($NOMATCHLOG_DB_FILE, %n_db); 

print "Program finished.\n";
exit;

# Copy the keys and values of a hash to a persistent file on disk.
sub save_db {
  my $name = shift;
#  my %hash = shift;
  print "    $name\n";
  my %db_tmp;
  tie %db_tmp, "DB_File", $name, O_CREAT, 0755 or die "Cannot create '$name': $!"; 
  $db_tmp{"a"} = "a"; 
#  %db_tmp = %hash;
  untie %db_tmp;
}

1;