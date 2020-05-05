#!/usr/bin/perl 
#$rcs = ' $Id: terminator.pl,v 1.0 2004/03/30 00:00:00 Exp $ ' ;

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

# If terminator.pl uses too much CPU, comment in the next two lines. "nice" takes
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
  log_error("terminator1", "The DB_File module was not found.");
  exit;
}

print "<br>before terminator\n";
################### ====== main control ======= #######################
  my %job_status_dbfile;
  my $job_id;
  my %user_status_dbfile;
  my $sch_start_time = time();
  my $sch_end_time;
  my $db_key;
  my @temp_user_id_list1 = ();
  my @temp_user_id_list2 = ();
  my @warn_user_id_list  = ();
  my @term_user_id_list  = ();
  my $user_id;
  my $warn_count = 0;
  my $warn_error_count = 0;
  my $term_count = 0;
  my $term_error_count = 0;
  my $last_search_use_date;
  my $error_ind = 0;
  my ($complete_time, $msgtxt, $mail_rtrn_code, $mail_rtrn_msg);
  my $return_code = 0;
  my $return_msg = undef;

  #
  # Check to see if there is another terminator running. If yes, then exist.
  #
  eval {
    use Fcntl;
    tie %job_status_dbfile, $db_package, $JOB_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $JOB_STATUS_DB_FILE: $!";
    $db_key = "terminator";
    if (!defined $job_status_dbfile{$db_key}) {
      $job_status_dbfile{$db_key} = $sch_start_time;
      $job_id = "terminator".time();
      # logging that the job has started
      log_error ($job_id, "----------- started -----------");
print "<br> job started\n";
    } else {
      log_error ("terminator2", "Exiting as another terminator is running");
print "<br> job exiting as another terminator is running\n";
      untie %job_status_dbfile;
      exit;
    }
    untie %job_status_dbfile;
  };
  if ($@) {
    log_error ("terminator3", $@);
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
  #     status_type = 5 = 30 day warning date
  #
print "<br> sch_start_time = $sch_start_time \n";
  eval {
    use Fcntl;
    tie %user_status_dbfile, $db_package, $USER_STATUS_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_STATUS_DB_FILE: $!";
    while (($db_key, $last_search_use_date) = each %user_status_dbfile) {
      $user_id       = substr($db_key, 0, 7);
      $status_type   = substr($db_key, -1);
print "<br> userstatus - key = $db_key last_search_use_date = $last_search_use_date \n";
      if ($status_type == 2) {
        if (($sch_start_time - $last_search_use_date) > 2592000) && ($sch_start_time - $last_search_use_date) < 3888000)) {
          push @warn_user_id_list, $user_id;
        }
        if ($sch_start_time - $last_search_use_date) >= 3888000) {
          push @term_user_id_list, $user_id;
        }
      }
    }
    untie %user_status_dbfile;
  };
  if ($@) {
    log_error ("terminator4", $@);
print "<br>error4 $@\n";
    $error_ind = 1;
  }

  if ($error_ind == 0) {

    foreach $user_id (@warn_user_id_list) {
print "<br> user $user_id is picked to be warned \n";
      ($return_code, $return_msg) = p_warn($user_id);
      if ($return_code == 0) {
print "<br> user $user_id is warned \n";
        $warn_count++;
      } elsif ($return_code > 1) {
        $warn_error_count++;
      }
    }

    foreach $user_id (@term_user_id_list) {
print "<br> user $user_id is picked to be terminated \n";
      ($return_code, $return_msg) = p_terminator($user_id);
      if ($return_code == 0) {
print "<br> user $user_id is terminated \n";
        $term_count++;
      } elsif ($return_code > 1) {
        $term_error_count++;
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

The Terminator program has run and finished successfully.

Following are the results of the Terminator:

  Program started at       : $started_time
  Total warnings created   : $warn_count
  Total warnings errored   : $warn_error_count
  Total users terminated   : $term_count
  Total terminates error   : $term_error_count
  Program finished at      : $complete_time
  Return Code              : $return_code
  Return Message           : $return_msg

Sincerely,
Terminator Program.

__STOP_OF_MAIL__

  ($mail_rtrn_code, $mail_rtrn_msg) = p_sendemail("jobs\@grepin.com","contact\@grepin.com","kishore\@grepin.com","Terminator Job - $return_code",$msgtxt,, );
  if ($mail_rtrn_code > 0) {
    log_error ("terminator6", $mail_rtrn_msg);
print "<br> error6 $mail_rtrn_msg \n";
  }
print "<br> success - email sent\n";

  #
  # At closing this terminator, update the job_status dbfile to indicate that it is not running any more.
  #
  eval {
    use Fcntl;
    tie %job_status_dbfile, $db_package, $JOB_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $JOB_STATUS_DB_FILE: $!";
    $db_key = "terminator";
    delete $job_status_dbfile{$db_key};
    untie %job_status_dbfile;
print "<br> job ended\n";
  };

  if ($@) {
    log_error ("terminator7", $@);
print "<br>error7 $@ \n";
  }

  # logging that the job has ended
  log_error ($job_id, "------------ ended ------------");

  exit;




##########  SUBROUTINES START HERE ########################
######################################################################################

sub p_warn {
# warn about the expiring of an account
# return codes
#  0 = success

  my $user_id    = $query->param('uid');
  my $return_code;
  my $return_msg;
  my %userprof_dbfile;
  my %userstatus_dbfile;
  my $warnlog  = $LOG_DIR.'30daywarnlog.txt';
  my $db_key;
  my $email_id;
  my @line = ();
  my $searchlogfile_base = $SRCH_USER_DIR.$user_id.'/log/searchlog';
  my $searchlogfile;

  use Fcntl;

  eval {
    tie %userprof_dbfile, "DB_File", $USER_PROFILE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";   
    tie %userstatus_dbfile, "DB_File", $USER_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_STATUS_DB_FILE: $!";   

    $db_key = $user_id;
    
    if ($userprof_dbfile{$db_key}) {
      ($email_id, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $userprof_dbfile{$db_key});
    }
    $db_key = $user_id.'-5';
    if (!$userstatus_dbfile{$db_key}) {
      $userstatus_dbfile{$db_key} = time();
    }
  };
  if ($@){
    log_error("terminator9",$@);
    return (99, $internal_error);
  }

  push(@line, 'terminator ',
              $user_id,
              ' - warned on ',
              localtime time());

  eval {
    use Fcntl ':flock';        # import LOCK_* constants
    open (WARNLOG, ">>$warnlog")
        or die "Unable to append to terminatorlog: $!\n";
    flock(WARNLOG, LOCK_EX);
    seek(WARNLOG, 0, 2);
    print WARNLOG join(':::', @line).":::\n";
    flock(WARNLOG, LOCK_UN);
    close(WARNLOG);
  };
  if ($@){
    log_error("terminator10",$@);
    return (99, $internal_error);
  }

  return (0, "success");

}



sub p_terminate {
# terminate my account
# return codes
#  0 = success

  my $user_id    = $query->param('uid');
  my $return_code;
  my $return_msg;
  my %userpwd_dbfile;
  my %userprof_dbfile;
  my %useridxdata_dbfile;
  my %usertmpldata_dbfile;
  my %userstatus_dbfile;
  my $user_directory = $SRCH_USER_DIR.$user_id.'/';
  my $terminatorlog  = $LOG_DIR.'terminatorlog.txt';
  my $db_key;
  my $email_id;
  my @line = ();
  my $searchlogfile_base = $SRCH_USER_DIR.$user_id.'/log/searchlog';
  my $searchlogfile;

  use Fcntl;
  use File::Path;

  eval {
    rmtree($user_directory) or die "Cannot delete user directory '$user_directory': $!";
  };
  if ($@){
    log_error("terminator8", $@);
    return (99, $internal_error);
  }

  eval {
    tie %userprof_dbfile, "DB_File", $USER_PROFILE_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";   
    tie %userpwd_dbfile, "DB_File", $USER_PWD_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_PWD_DB_FILE: $!";   
    tie %useridxdata_dbfile, "DB_File", $USER_INDEX_DATA_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_INDEX_DATA_DB_FILE: $!";   
    tie %usertmpldata_dbfile, "DB_File", $USER_TEMPLATE_DATA_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_TEMPLATE_DATA_DB_FILE: $!";   
    tie %userstatus_dbfile, "DB_File", $USER_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_STATUS_DB_FILE: $!";   

    $db_key = $user_id;
    
    if ($userprof_dbfile{$db_key}) {
      ($email_id, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15, $d16, $d17, $d18) = unpack("C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A* C/A*", $userprof_dbfile{$db_key});
      delete $userprof_dbfile{$db_key};
    }
    if ($useridxdata_dbfile{$db_key}) {
      delete $useridxdata_dbfile{$db_key};
    }
    if ($usertmpldata_dbfile{$db_key}) {
      delete $usertmpldata_dbfile{$db_key};
    }

    $db_key = $user_id.'-1';
    if ($userstatus_dbfile{$db_key}) {
      delete $userstatus_dbfile{$db_key};
    }
    $db_key = $user_id.'-2';
    if ($userstatus_dbfile{$db_key}) {
      delete $userstatus_dbfile{$db_key};
    }
    $db_key = $user_id.'-3';
    if ($userstatus_dbfile{$db_key}) {
      delete $userstatus_dbfile{$db_key};
    }
    $db_key = $user_id.'-4';
    if ($userstatus_dbfile{$db_key}) {
      delete $userstatus_dbfile{$db_key};
    }
    $db_key = $user_id.'-5';
    if ($userstatus_dbfile{$db_key}) {
      delete $userstatus_dbfile{$db_key};
    }

    $db_key = $email_id;
    if ($userpwd_dbfile{$db_key}) {
      delete $userpwd_dbfile{$db_key};
    }
  };
  if ($@){
    log_error("terminator9",$@);
    return (99, $internal_error);
  }

  push(@line, 'terminator ',
              $user_id,
              ' - terminated on ',
              localtime time();

  eval {
    use Fcntl ':flock';        # import LOCK_* constants
    open (TERMLOG, ">>$terminatorlog")
        or die "Unable to append to terminatorlog: $!\n";
    flock(TERMLOG, LOCK_EX);
    seek(TERMLOG, 0, 2);
    print TERMLOG join(':::', @line).":::\n";
    flock(TERMLOG, LOCK_UN);
    close(TERMLOG);
  };
  if ($@){
    log_error("terminator10",$@);
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
    log_error ("p_sendemail1 - terminator", $@);
    return (99, $internal_error);
  }
  return(0, "success");

}


1;