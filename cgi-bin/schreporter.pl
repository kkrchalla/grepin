#!/usr/bin/perl 
#$rcs = ' $Id: schreporter.pl,v 1.0 2004/03/30 00:00:00 Exp $ ' ;

BEGIN {
   use CGI::Carp qw(carpout);
   open (ERRORLOG, ">>/home/grepinco/public_html/cgi-bin/log/errorlog.txt")
       or die "Unable to append to errorlog: $!\n";
   carpout(*ERRORLOG);
}

print "Content-Type: text/html\n\n";
print "at the beginning\n";

# Grepin Search and Services
# Copyright (C) 2004 Grepin Search and Services <contact@grepin.com>

use Fcntl;
use MIME::Lite;
use CGI;

# If schreporter.pl uses too much CPU, comment in the next two lines. "nice" takes
# a value between 0 (normal) and 19 (lowest priority). Tested on Linux only.
#use POSIX qw(nice);
#nice 19;
  
# added program path to @INC because it fails to find ./conf.pl if
# started from other directory
{ 
  # block is for $1 not mantaining its value
  $0 =~ /(.*)(\\|\/)/;
  push @INC, $1 if $1;
}

package main;

my $query = new CGI;

my $password = $query->param('pwd');
if ($password ne 'mzlapqnxksowbcjdie'){
  print "You are not authorized to invoke this program.\n";
  exit;
}

my $MAIN_DIR = '/home/grepinco/public_html/cgi-bin/';
my $USER_DIR = $MAIN_DIR.'users/';
my $LOG_DIR  = $MAIN_DIR.'log/';

my $SRCH_DIR      = $MAIN_DIR.'search/';
my $SRCH_USER_DIR = $SRCH_DIR.'users/';

my $LOG_FILE = $JOB_DIR.'joblog.txt';

my $JOB_STATUS_DB_FILE   = $USER_DIR.'jobstatus';
my $USER_PROFILE_DB_FILE = $USER_DIR.'userprof';
my $QUEUE_DB_FILE        = $USER_DIR.'queue';
my $REPORT_QUEUE_DB_FILE = $USER_DIR.'rprtqueue';

my $db_package = "";
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
if( $db_package  ne 'DB_File' ) {
  log_error("schreporter1", "The DB_File module was not found.");
  exit;
}

print "<br>before scheduler\n";
################### ====== main control ======= #######################
  my %job_status_dbfile;
  my $job_id;
  my %user_prof_dbfile;
  my $sch_start_time = time();
  my $sch_end_time;
  my $db_key;
  my @user_id_list = ();
  my @temp_user_id_list = ();
  my $user_id;
  my $error_ind = 0;
  my ($complete_time, $msgtxt, $mail_rtrn_code, $mail_rtrn_msg);
  my ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15);
  my $return_code = 0;
  my $return_msg  = undef;

  #
  # Check to see if there is another schreporter running. If yes, then exist.
  #
  eval {
    use Fcntl;
    tie %job_status_dbfile, $db_package, $JOB_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $JOB_STATUS_DB_FILE: $!";
    $db_key = "schreporter";
    if (!defined $job_status_dbfile{$db_key}) {
      $job_status_dbfile{$db_key} = $sch_start_time;
      $job_id = "schreporter".time();
      # logging that the job has started
      log_error ($job_id, "----------- started -----------");
print "<br> job started\n";
    } else {
      log_error ("schreporter2", "Exiting as another schreporter is running");
print "<br> exiting as another schreporter is running\n";
      untie %job_status_dbfile;
      exit;
    }
    untie %job_status_dbfile;
  };
  if ($@) {
    log_error ("schreporter3", $@);
print "<br>error3 $@\n";
    exit;
  }

  #
  # Read the user profile file to get all the user ids to be processed
  #
  eval {
    use Fcntl;
    tie %user_prof_dbfile, $db_package, $USER_PROFILE_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";
    $user_count = keys %user_prof_dbfile;
    push(@user_id_list, keys %user_prof_dbfile);
    untie %user_prof_dbfile;
  };
  if ($@) {
    log_error ("schreporter4", $@);
print "<br>error4 $@\n";
    $error_ind = 1;
  }

  if ($error_ind == 0) {

    foreach $user_id (@user_id_list) {
      ($return_code, $return_msg) = p_updatefiles($user_id);
    }

    if ($return_code == 0) {
      eval {
        my $pid = fork();
        if ($pid == 0) {
          close STDIN;
          close STDOUT;
          close STDERR;

          exec ("/home/grepinco/public_html/cgi-bin/bsendrprt.pl");
print "<br> bsendrprt submitted \n";
        } elsif (!defined $pid) {
          die "fork failed during bsendrprt submitting in schreporter";
        }
      };
      if ($@){
        log_error("schreporter5", $@);
      }
    }
  } else {
    $return_code = 90;
    $return_msg  = "Error occured while selecting the users list";
  }

  $complete_time = localtime time();
  $started_time  = localtime $sch_start_time;
  $msgtxt = <<__STOP_OF_MAIL__;
Hello Kishore,

Now the time is $complete_time.

The Schedule Reporter program has run and finished successfully.

Following are the results of the Schedule Reporter:

  Program started at       : $started_time
  Total users processed    : $user_count
  Program finished at      : $complete_time
  Return Code              : $return_code
  Return Message           : $return_msg

Sincerely,
Schedule Reporter Program.

__STOP_OF_MAIL__

  ($mail_rtrn_code, $mail_rtrn_msg) = p_sendemail("jobs\@grepin.com","contact\@grepin.com","kishore\@grepin.com","Schedule Reporter Job - $return_code" ,$msgtxt,, );
  if ($mail_rtrn_code > 0) {
    log_error ("schreporter6", $mail_rtrn_msg);
print "<br>error6 $mail_rtrn_msg \n";
  }
print "<br> success - email sent\n";

  #
  # At closing this schreporter, update the job_status dbfile to indicate that it is not running any more.
  #
  eval {
    use Fcntl;
    tie %job_status_dbfile, $db_package, $JOB_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $JOB_STATUS_DB_FILE: $!";
    $db_key = "schreporter";
    delete $job_status_dbfile{$db_key};
    untie %job_status_dbfile;
print "<br> success job ended\n";
  };

  if ($@) {
    log_error ("schreporter7", $@);
print "<br>error7 $@ \n";
  }

  # logging that the job has ended
  log_error ($job_id, "------------ ended ------------");

  exit;




##########  SUBROUTINES START HERE ########################
######################################################################################

sub p_updatefiles {

  my $user_id = shift;
  my %queue_dbfile;
  my %report_queue_dbfile;
  my $db_key;
  my $last_used_queue;
  my $last_processed_queue;
  my $queue_time;
  my $report_type = 'scheduled';
  my ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15);
  my $internal_error = "An internal error occurred. Sorry for the inconvenience.<br /> Please inform the webmaster about the error at contact\@grepin.com.";

  use Fcntl;

  #
  # Get the last used queue number and update it with the next key
  #
  eval {
    use Fcntl;
    tie %queue_dbfile, "DB_File", $QUEUE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $QUEUE_DB_FILE: $!";   
    $db_key = "report";
    if ($queue_dbfile{$db_key}) {
      ($last_used_queue, $last_processed_queue) = unpack("C/A* C/A*", $queue_dbfile{$db_key});
      $last_used_queue++;
    } else {
      $last_used_queue      = 1;
      $last_processed_queue = 0;
    }
    $queue_dbfile{$db_key} = pack('C/A* C/A*',$last_used_queue, $last_processed_queue);
    untie %queue_dbfile;
print "<br> last_used_queue = $last_used_queue last_processed_queue = $last_processed_queue \n";
  };
  if ($@){
    log_error("schreporter8", $@);
    return (99, $internal_error);
  }

  #
  # Update the report queue dbfile with the next queue and user_id
  #
  eval {
    use Fcntl;
    tie %report_queue_dbfile, "DB_File", $REPORT_QUEUE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $REPORT_QUEUE_DB_FILE: $!";   
    $db_key = $last_used_queue;
    $queue_time = time();
    $d1 = undef;
    $d2 = undef;
    $d3 = undef;
    $d4 = undef;
    $report_queue_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_id, $report_type, $queue_time, $d1, $d2, $d3, $d4);
    untie %report_queue_dbfile;
print "<br> report added to queue = $db_key with user = $user_id and reporttype = $report_type \n";
  };
  if ($@){
    log_error("schreporter9", $@);
    return (99, $internal_error);
  }

  return (0, "success");
}




sub log_error {
# log error in the error file
# return codes
#  0 = success
# 99 = database error

  my $log_process   = shift;
  my $log_message   = shift;
  my @line = ();
  my $addr = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'};

  use Fcntl;

  push(@line, $log_process || '-',
              $log_message || '-',
              $query->param('cmd') || '-',
              $query->param('fn') || '-',
              $query->param('arg') || '-',
              $query->param('uid') || '-',
              $query->param('sid') || '-',
              localtime time() || '-',
              $addr || '-');

  use Fcntl ':flock';        # import LOCK_* constants
  open(LOG, ">>$LOG_FILE") or die "Cannot open logfile '$LOG_FILE' for writing: $!";
  flock(LOG, LOCK_EX);
  seek(LOG, 0, 2);
  print LOG join(':::', @line).":::\n";
  flock(LOG, LOCK_UN);
  close(LOG);

  return (0, "success");

}



######################################################################################


sub p_sendemail  {
# return codes
#  0 success
#  1 to empty
#  2 from empty
#  3 subject empty
#  4 message body empty
#
#  Sample call:
#  sendemail($from, $reply, $to, $subject, $message, $attachment, $attachment_name );

  my ($fromaddr, $replyaddr, $to, $subject, $message, $attachment, $attachment_name) = @_;
  my $internal_error = "An internal error occurred. Sorry for the inconvenience.<br /> Please inform the webmaster about the error at contact\@grepin.com.";
  my $mailer;

  use Fcntl;

  $to =~ s/[ \t]+/, /g; # pack spaces and add comma
  $fromaddr =~ s/.*<([^\s]*?)>/$1/; # get from email address
  $replyaddr =~ s/.*<([^\s]*?)>/$1/; # get reply email address
  $replyaddr =~ s/^([^\s]+).*/$1/; # use first address
  $message =~ s/^\./\.\./gm; # handle . as first character
  $message =~ s/\r\n/\n/g; # handle line ending
  $message =~ s/\n/\r\n/g;

  if (!$to) {
    return(1, "to email is empty");
  }
  if (!$fromaddr) {
    return(2, "from address is empty");
  }
  if (!$subject) {
    return(3, "subject is empty");
  }
  if (!$message) {
    return(4, "message body is empty");
  }

  eval {
    $mailer = MIME::Lite->new(
                    From    => $fromaddr,
                    To      => $to,
                    Subject => $subject,
                    Data    => $message
                    );
    $mailer->send();
  };
  if ($@) {
    log_error ("p_sendemail1 - schreporter", $@);
    return (99, $internal_error);
  }
  return(0, "success");

}


1;