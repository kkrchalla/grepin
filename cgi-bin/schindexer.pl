#!/usr/bin/perl -w
#$rcs = ' $Id: schindexer.pl,v 1.0 2004/03/30 00:00:00 Exp $ ' ;

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
#   use CGI::Carp qw(carpout);
#   open (ERRORLOG, ">>/home/grepinco/public_html/cgi-bin/log/errorlog.txt")
#       or die "Unable to append to errorlog: $!\n";
#   carpout(*ERRORLOG);
}

print "Content-Type: text/html\n\n";
print "at the beginning\n";

# Grepin Search and Services
# Copyright (C) 2004 Grepin Search and Services <contact@grepin.com>

use Fcntl;
use MIME::Lite;
use CGI;

# If schindexer.pl uses too much CPU, comment in the next two lines. "nice" takes
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
if ($ENV{'REQUEST_METHOD'} && ($password ne 'mzlapqnxksowbcjdie')){
  print "You are not authorized to invoke this program.\n";
  exit;
}

my $MAIN_DIR = '/home/grepinco/public_html/cgi-bin/';
my $USER_DIR = $MAIN_DIR.'users/';
my $LOG_DIR  = $MAIN_DIR.'log/';

my $SRCH_DIR      = $MAIN_DIR.'search/';
my $SRCH_USER_DIR = $SRCH_DIR.'users/';

my $LOG_FILE = $LOG_DIR.'joblog.txt';

my $JOB_STATUS_DB_FILE      = $USER_DIR.'jobstatus';
my $USER_STATUS_DB_FILE     = $USER_DIR.'userstatus';
my $USER_PROFILE_DB_FILE    = $USER_DIR.'userprof';
my $USER_INDEX_DATA_DB_FILE = $USER_DIR.'userindxdata';
my $QUEUE_DB_FILE           = $USER_DIR.'queue';
my $INDEX_QUEUE_DB_FILE     = $USER_DIR.'indxqueue';

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
  log_error("schindexer1", "The DB_File module was not found.");
  exit;
}

print "<br>before scheduler\n";
################### ====== main control ======= #######################
  my %job_status_dbfile;
  my $job_id;
  my %user_status_dbfile;
  my $sch_start_time = time();
  my $sch_end_time;
  my $db_key;
  my @user_id_list = ();
  my @temp_user_id_list = ();
  my $user_id;
  my $last_indexed_date;
  my $config_status;
  my $error_ind = 0;
  my ($complete_time, $msgtxt, $mail_rtrn_code, $mail_rtrn_msg);
  my $return_code = 0;
  my $return_msg = undef;
  #
  # Check to see if there is another schindexer running. If yes, then exist.
  #
  eval {
    use Fcntl;
    tie %job_status_dbfile, $db_package, $JOB_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $JOB_STATUS_DB_FILE: $!";
    $db_key = "schindexer";
    if (!defined $job_status_dbfile{$db_key}) {
      $job_status_dbfile{$db_key} = $sch_start_time;
      $job_id = "schindexer".time();
      # logging that the job has started
      log_error ($job_id, "----------- started -----------");
print "<br> job started\n";
    } elsif (time() - $job_status_dbfile{$db_key} < 86399) {
      log_error ("schindexer2", "Exiting as another schindexer is running");
print "<br> job exiting as another schindexer is running\n";
      untie %job_status_dbfile;
      exit;
    } else {
      $job_status_dbfile{$db_key} = time();
      $job_id = "schindexer".time();
      # logging again that the job has started
      log_error ($job_id, "----------- started -----------");
    }
    untie %job_status_dbfile;
  };
  if ($@) {
    log_error ("schindexer3", $@);
print "<br>error3 - $@\n";
    exit;
  }

  #
  # Read the user status file to get all the user ids to be processed
  #   key = user_id + '-' + status_type
  #     status_type = 1 = last_indexed_date
  #     status_type = 2 = last_search_use_date
  #     status_type = 3 = member_status (F = free, S = subscription)
  #     status_type = 4 = config_status (I, IQ, S, IS, IQS)
  #
print "<br> sch_start_time = $sch_start_time \n";
  eval {
    use Fcntl;
    tie %user_status_dbfile, $db_package, $USER_STATUS_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_STATUS_DB_FILE: $!";
    while (($db_key, $last_indexed_date) = each %user_status_dbfile) {
      $user_id       = substr($db_key, 0, 7);
      $status_type   = substr($db_key, -1);
print "<br> userstatus - key = $db_key last_indexed_date = $last_indexed_date \n";
      if (($status_type == 1) && (($sch_start_time - $last_indexed_date) > 3888000)) {
        push @temp_user_id_list, $user_id;
      }
    }
    foreach $user_id (@temp_user_id_list) {
      $db_key = $user_id.'-4';
      $config_status = $user_status_dbfile{$db_key};
      if (($config_status eq "I") || ($config_status eq "IS")) {
        push @user_id_list, $user_id;
        $user_count++;
print "<br> user $user_id is picked to be scheduled \n";
      }
    }
    untie %user_status_dbfile;
  };
  if ($@) {
    log_error ("schindexer4", $@);
print "<br>error4 $@\n";
    $error_ind = 1;
  }

print "<br> total of $user_count users are picked to be scheduled \n";

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

          exec ("/home/grepinco/public_html/cgi-bin/grepinbot.pl");
        } elsif (!defined $pid) {
          die "fork failed during grepinbot submitting in schindexer";
        }
print "<br> grepinbot is submitted \n";
      };
      if ($@){
        log_error("schindexer5", $@);
        $return_code = 99;
        $return_msg  = "Schedule indexer failed while submitting grepinbot";
print "<br>error5 $@\n";
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

The Schedule Indexer program has run and finished successfully.

Following are the results of the Schedule Indexer:

  Program started at       : $started_time
  Total users processed    : $user_count
  Program finished at      : $complete_time
  Return Code              : $return_code
  Return Message           : $return_msg

Sincerely,
Schedule Indexer Program.

__STOP_OF_MAIL__

  ($mail_rtrn_code, $mail_rtrn_msg) = p_sendemail("jobs\@grepin.com","contact\@grepin.com","kishore\@grepin.com","Schedule Indexer Job - $return_code",$msgtxt,, );
  if ($mail_rtrn_code > 0) {
    log_error ("schindexer6", $mail_rtrn_msg);
print "<br> error6 $mail_rtrn_msg \n";
  }
print "<br> success - email sent\n";

  #
  # At closing this schindexer, update the job_status dbfile to indicate that it is not running any more.
  #
  eval {
    use Fcntl;
    tie %job_status_dbfile, $db_package, $JOB_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $JOB_STATUS_DB_FILE: $!";
    $db_key = "schindexer";
    delete $job_status_dbfile{$db_key};
    untie %job_status_dbfile;
print "<br> job ended\n";
  };

  if ($@) {
    log_error ("schindexer7", $@);
print "<br>error7 $@ \n";
  }

  # logging that the job has ended
  log_error ($job_id, "------------ ended ------------");

  exit;




##########  SUBROUTINES START HERE ########################
######################################################################################

sub p_updatefiles {
# update the appropriate files
# return codes
#  0 = success
# 99 = database error

  my $user_id   = shift;
  my %user_status_dbfile;
  my %queue_dbfile;
  my %index_queue_dbfile;
  my %user_prof_dbfile;
  my $db_key;
  my $last_used_queue;
  my $last_processed_queue;
  my $queue_time;
  my ($email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4);
  my ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15);
  my $internal_error = "An internal error occurred. Sorry for the inconvenience.<br /> Please inform the webmaster about the error at contact\@grepin.com.";

  use Fcntl;

  #
  # Get the last used queue number and update it with the next key
  #
  eval {
    use Fcntl;
    tie %queue_dbfile, "DB_File", $QUEUE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $QUEUE_DB_FILE: $!";   
    $db_key = "index";
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
    log_error("schindexer8", $@);
print "<br>error8 $@ \n";
    return (99, $internal_error);
  }

  #
  # Update the index queue dbfile with the next queue and user_id
  #
  eval {
    use Fcntl;
    tie %index_queue_dbfile, "DB_File", $INDEX_QUEUE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $INDEX_QUEUE_DB_FILE: $!";   
    $db_key = $last_used_queue;
    $queue_time = time();
    $d1 = undef;
    $d2 = undef;
    $d3 = undef;
    $d4 = undef;
    $d5 = undef;
    $index_queue_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_id, $queue_time, $d1, $d2, $d3, $d4, $d5);
    untie %index_queue_dbfile;
print "<br> index queue file updated for key = $db_key with user $user_id \n";
  };
  if ($@){
    log_error("schindexer9", $@);
print "<br>error9 $@ \n";
    return (99, $internal_error);
  }

  #
  # Update the config_status in the user_prof_dbfile
  #
  eval {
    use Fcntl;
    tie %user_prof_dbfile, "DB_File", $USER_PROFILE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";   
    $db_key = $user_id;
    ($email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $user_prof_dbfile{$db_key});
    if (($config_status eq "IS") || ($config_status eq "S") || ($config_status eq "IQS")) {
      $config_status = "IQS"
    } else {
      $config_status = "IQ"
    }
    $user_prof_dbfile{$db_key} = pack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $email_id, $web_addr, $web_type, $name, $phone, $addr1, $addr2, $city, $state, $zip, $country, $add_date, $update_date, $member_status, $config_status, $cat1, $cat2, $cat3, $cat4);
    untie %user_prof_dbfile;
print "<br> prifile file updated for user = $db_key with status = $config_status \n";
  };
  if ($@){
    log_error("schindexer10", $@);
print "<br>error10 $@ \n";
    return (99, $internal_error);
  }

  #
  # update the user_status_dbfile with config_status 
  #   key = user_id + '-' + status_type
  #     status_type = 1 = last_indexed_date
  #     status_type = 2 = last_search_use_date
  #     status_type = 3 = member_status (F = free, S = subscription)
  #     status_type = 4 = config_status (I, IQ, S, IS, IQS)
  #
  eval {
    use Fcntl;
    tie %user_status_dbfile, $db_package, $USER_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_STATUS_DB_FILE: $!";
    $db_key = $user_id.'-4';
    $user_status_dbfile{$db_key} = $config_status;
    untie %user_status_dbfile;
print "<br> status file updated for key = $db_key with status = $config_status \n";
  };
  if ($@) {
    log_error ("schindexer11", $@);
print "<br>error11 $@ \n";
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
  my $mailer;
  my $internal_error = "An internal error occurred. Sorry for the inconvenience.<br /> Please inform the webmaster about the error at contact\@grepin.com.";

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
    log_error ("p_sendemail1 - schindexer", $@);
    return (99, $internal_error);
  }
  return(0, "success");

}


1;