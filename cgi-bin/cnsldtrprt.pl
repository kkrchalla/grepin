#!/usr/bin/perl -w
#$rcs = ' $Id: cnsldtrprt.pl,v 1.0 2004/03/30 00:00:00 Exp $ ' ;

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

# If cnsldtrprt.pl uses too much CPU, comment in the next two lines. "nice" takes
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

my $LOG_FILE = $LOG_DIR.'joblog.txt';

my $USER_PROFILE_DB_FILE     = $USER_DIR.'userprof';
my $JOB_STATUS_DB_FILE       = $USER_DIR.'jobstatus';
my $USER_STATUS_DB_FILE      = $USER_DIR.'userstatus';

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
  log_error("cnsldtrprt1", "The DB_File module was not found.");
  exit;
}

print "<br>before scheduler\n";
################### ====== main control ======= #######################
  my %job_status_dbfile;
  my $job_id;
  my $sch_start_time = time();
  my $sch_end_time;
  my $db_key;
  my @user_id_list = ();
  my $user_id;
  my %user_prof_dbfile;
  my %searchlogmth_dbfile;
  my %nomatchlogmth_dbfile;
  my %searchlog_dbfile;
  my %nomatchlog_dbfile;
  my $error_ind = 0;
  my ($user_count, $error_count, $success_count) = (0, 0, 0);
  my ($complete_time, $msgtxt, $mail_rtrn_code, $mail_rtrn_msg);
  my ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10, $d11, $d12, $d13, $d14, $d15);
  my $return_code = 0;
  my $return_msg  = undef;

  #
  # Check to see if there is another cnsldtrprt running. If yes, then exist.
  #
  eval {
    use Fcntl;
    tie %job_status_dbfile, $db_package, $JOB_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $JOB_STATUS_DB_FILE: $!";
    $db_key = "cnsldtrprt";
    if (!defined $job_status_dbfile{$db_key}) {
      $job_status_dbfile{$db_key} = $sch_start_time;
      $job_id = "cnsldtrprt".time();
      # logging that the job has started
      log_error ($job_id, "----------- started -----------");
print "<br> job started\n";
    } elsif (time() - $job_status_dbfile{$db_key} < 172799) {
      log_error ("cnsldtrprt2", "Exiting as another cnsldtrprt is running");
print "<br> exiting as another cnsldtrprt is running\n";
      untie %job_status_dbfile;
      exit;
    } else {
      $job_status_dbfile{$db_key} = time();
      $job_id = "cnsldtrprt".time();
      # logging again that the job has started
      log_error ($job_id, "----------- started -----------");
    }
    untie %job_status_dbfile;
  };
  if ($@) {
    log_error ("cnsldtrprt3", $@);
print "<br>error3 $@\n";
    exit;
  }

  #
  # Read the user profile file to get all the user ids to be processed
  #
  if ($error_ind == 0) {
    eval {
      use Fcntl;
      tie %user_prof_dbfile, $db_package, $USER_PROFILE_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_PROFILE_DB_FILE: $!";
      $user_count = keys %user_prof_dbfile;
      push(@user_id_list, keys %user_prof_dbfile);
      untie %user_prof_dbfile;
    };
    if ($@) {
      log_error ("cnsldtrprt4", $@);
print "<br>error4 $@\n";
      $error_ind = 1;
    }
  }

  if ($error_ind == 0) {
    foreach $user_id (@user_id_list) {
      ($return_code, $return_msg) = p_cnsldt_srch($user_id);
      if ($return_code == 0) {
        $success_count++;
      } else {
        $return_msg = $user_id.' - '.$return_msg;
        log_error ("cnsldtrprt5", $return_msg);
        $error_count++;
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

The Consolidate Reports program has run and finished successfully.

Following are the results of the Consolidate Reports:

  Program started at       : $started_time
  Total users processed    : $user_count
  Total successful search  : $success_count
  Total errored search     : $error_count
  Program finished at      : $complete_time
  Return Code              : $return_code
  Return Message           : $return_msg

Sincerely,
Consolidate Report Program.

__STOP_OF_MAIL__

  ($mail_rtrn_code, $mail_rtrn_msg) = p_sendemail("jobs\@grepin.com","contact\@grepin.com","kishore\@grepin.com","Consolidate Reports Job - $return_code",$msgtxt,, );
  if ($mail_rtrn_code > 0) {
    log_error ("cnsldtrprt6", $mail_rtrn_msg);
print "<br>error6 $mail_rtrn_msg \n";
  }
print "<br> success - email sent\n";

  #
  # At closing this cnsldtrprt, update the job_status dbfile to indicate that it is not running any more.
  #
  eval {
    use Fcntl;
    tie %job_status_dbfile, $db_package, $JOB_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $JOB_STATUS_DB_FILE: $!";
    $db_key = "cnsldtrprt";
    delete $job_status_dbfile{$db_key};
    untie %job_status_dbfile;
print "<br> success jobended\n";
  };

  if ($@) {
    log_error ("cnsldtrprt7", $@);
print "<br>error7 $@ \n";
  }

  # logging that the job has ended
  log_error ($job_id, "------------ ended ------------");

  exit;







##########  SUBROUTINES START HERE ########################
######################################################################################

sub p_cnsldt_srch {

  my $user_id = shift;
  my $SRCH_USER_LOG_DIR = $MAIN_DIR.'users/users/'.$user_id.'/search/log/';

  my $searchlogfile_base    = $SRCH_USER_LOG_DIR.'searchlog';
  my $searchlogfile;
  my $db_key;
  my %user_status_dbfile;
  my $last_search_use_date  = undef;
  my $last_consolidate_date = undef;
  my $day_of_month;          # 1 - 31
  my $month;                 # 0 - 11
  my $yday;                  # 0 - 365
  my $yday_saved;
  my $loop;
  my @report_array;
  my @row_array;
  my %usersearchlogmth_dbfile;
  my %usernomatchlogmth_dbfile;
  my %usersearchlog_dbfile;
  my %usernomatchlog_dbfile;
  my %searchlogmth_dbfile;
  my %nomatchlogmth_dbfile;
  my $USERSEARCHLOG_MONTH_DB_FILE  = $SRCH_USER_LOG_DIR.'srchlogmth';
  my $USERNOMATCHLOG_MONTH_DB_FILE = $SRCH_USER_LOG_DIR.'nomatchmth';
  my $USERSEARCHLOG_DB_FILE        = $SRCH_USER_LOG_DIR.'srchlog';
  my $USERNOMATCHLOG_DB_FILE       = $SRCH_USER_LOG_DIR.'nomatchlog';
  my $SEARCHLOG_MONTH_DB_FILE      = $USER_DIR.'srchlogmth';
  my $NOMATCHLOG_MONTH_DB_FILE     = $USER_DIR.'nomatchmth';
  my $SEARCHLOG_DB_FILE            = $USER_DIR.'srchlog';
  my $NOMATCHLOG_DB_FILE           = $USER_DIR.'nomatchlog';

  #
  # get the last consolidate date from user_status_dbfile - last_search_use_date 
  #   key = user_id + '-' + status_type
  #     status_type = 1 = last_indexed_date
  #     status_type = 2 = last_search_use_date
  #     status_type = 3 = member_status (F = free, S = subscription)
  #     status_type = 4 = config_status (I, IQ, S, IS, IQS)
  #
  eval {
    use Fcntl;
    tie %user_status_dbfile, $db_package, $USER_STATUS_DB_FILE, O_RDONLY, 0755 or die "Cannot open $USER_STATUS_DB_FILE: $!";
    $db_key = $user_id.'-2';
    if ($user_status_dbfile{$db_key}) {
      $last_consolidate_date = $user_status_dbfile{$db_key};
    }
print "<br>error12 - userstatusdbfile - $db_key, $user_status_dbfile{$db_key}\n";
    untie %user_status_dbfile;
  };

  if ($@) {
    log_error ("cnsldtrprt8", $@);
print "<br>error8 $@ \n";
    return (99, $@);
  }

  ($day_of_month, $month, $yday) = (localtime time())[3,4,7];
  $yday_saved = $yday;
  $month++;   #increment it to make it between 1 and 12, instead of 0 and 11

  $USERSEARCHLOG_MONTH_DB_FILE  = $USERSEARCHLOG_MONTH_DB_FILE.$month;
  $USERNOMATCHLOG_MONTH_DB_FILE = $USERNOMATCHLOG_MONTH_DB_FILE.$month;
  $SEARCHLOG_MONTH_DB_FILE      = $SEARCHLOG_MONTH_DB_FILE.$month;
  $NOMATCHLOG_MONTH_DB_FILE     = $NOMATCHLOG_MONTH_DB_FILE.$month;
  eval {
    use Fcntl;
    tie %usersearchlogmth_dbfile, $db_package, $USERSEARCHLOG_MONTH_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USERSEARCHLOG_MONTH_DB_FILE: $!";
    tie %usernomatchlogmth_dbfile, $db_package, $USERNOMATCHLOG_MONTH_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USERNOMATCHLOG_MONTH_DB_FILE: $!";
    tie %usersearchlog_dbfile, $db_package, $USERSEARCHLOG_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USERSEARCHLOG_DB_FILE: $!";
    tie %usernomatchlog_dbfile, $db_package, $USERNOMATCHLOG_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USERNOMATCHLOG_DB_FILE: $!";
    tie %searchlogmth_dbfile, $db_package, $SEARCHLOG_MONTH_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $SEARCHLOG_MONTH_DB_FILE: $!";
    tie %nomatchlogmth_dbfile, $db_package, $NOMATCHLOG_MONTH_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $NOMATCHLOG_MONTH_DB_FILE: $!";
    tie %searchlog_dbfile, $db_package, $SEARCHLOG_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $SEARCHLOG_DB_FILE: $!";
    tie %nomatchlog_dbfile, $db_package, $NOMATCHLOG_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $NOMATCHLOG_DB_FILE: $!";
  };
  if ($@) {
    log_error ("cnsldtrprt9", $@);
print "<br>error9 $@\n";
    return (99, $@);
  }

  #
  # yday is today, but we want to start from yesterday so subtract 1 from yday.
  # and also from day_of_month.
  # we consolidate only 28 days of detail report so that we don't run into leap year problems
  #

  for ($loop = 1; $loop <= 28; $loop++) {
    if ($yday == 0) {						# this is jan 1st
      $yday = 365;						# this is dec 31st of leap year
      $searchlogfile = $searchlogfile_base.$yday;
      if (!(-e $searchlogfile)) {				# if dec 31st of leap year does not exist
        $yday = 364;						# making it dec 31st of non leap year
      }
      $day_of_month = 31;
      $month = 12;
      untie %usersearchlogmth_dbfile;			# closing all the last month searchlog db files
      untie %usernomatchlogmth_dbfile;			# and using the new month and then
      untie %searchlogmth_dbfile;				# opening the new month searchlog db files
      untie %nomatchlogmth_dbfile;
      $USERSEARCHLOG_MONTH_DB_FILE  = $USERSEARCHLOG_MONTH_DB_FILE.$month;
      $USERNOMATCHLOG_MONTH_DB_FILE = $USERNOMATCHLOG_MONTH_DB_FILE.$month;
      $SEARCHLOG_MONTH_DB_FILE      = $SEARCHLOG_MONTH_DB_FILE.$month;
      $NOMATCHLOG_MONTH_DB_FILE     = $NOMATCHLOG_MONTH_DB_FILE.$month;
      eval {
        use Fcntl;
        tie %usersearchlogmth_dbfile, $db_package, $USERSEARCHLOG_MONTH_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USERSEARCHLOG_MONTH_DB_FILE: $!";
        tie %usernomatchlogmth_dbfile, $db_package, $USERNOMATCHLOG_MONTH_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USERNOMATCHLOG_MONTH_DB_FILE: $!";
        tie %searchlogmth_dbfile, $db_package, $SEARCHLOG_MONTH_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $SEARCHLOG_MONTH_DB_FILE: $!";
        tie %nomatchlogmth_dbfile, $db_package, $NOMATCHLOG_MONTH_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $NOMATCHLOG_MONTH_DB_FILE: $!";
      };
      if ($@) {
        log_error ("cnsldtrprt10", $@);
print "<br>error10 $@\n";
        return (99, $@);
      }
    } else {
      $yday--;
      $day_of_month--;
      if ($day_of_month == 0) {
        $day_of_month = 31;
        $month--;
        untie %usersearchlogmth_dbfile;
        untie %usernomatchlogmth_dbfile;
        untie %searchlogmth_dbfile;
        untie %nomatchlogmth_dbfile;
        $USERSEARCHLOG_MONTH_DB_FILE  = $USERSEARCHLOG_MONTH_DB_FILE.$month;
        $USERNOMATCHLOG_MONTH_DB_FILE = $USERNOMATCHLOG_MONTH_DB_FILE.$month;
        $SEARCHLOG_MONTH_DB_FILE      = $SEARCHLOG_MONTH_DB_FILE.$month;
        $NOMATCHLOG_MONTH_DB_FILE     = $NOMATCHLOG_MONTH_DB_FILE.$month;
        eval {
          use Fcntl;
          tie %usersearchlogmth_dbfile, $db_package, $USERSEARCHLOG_MONTH_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USERSEARCHLOG_MONTH_DB_FILE: $!";
          tie %usernomatchlogmth_dbfile, $db_package, $USERNOMATCHLOG_MONTH_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USERNOMATCHLOG_MONTH_DB_FILE: $!";
          tie %searchlogmth_dbfile, $db_package, $SEARCHLOG_MONTH_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $SEARCHLOG_MONTH_DB_FILE: $!";
          tie %nomatchlogmth_dbfile, $db_package, $NOMATCHLOG_MONTH_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $NOMATCHLOG_MONTH_DB_FILE: $!";
        };
        if ($@) {
          log_error ("cnsldtrprt11", $@);
print "<br>error11 $@\n";
          return (99, $@);
        }
      }
    }
    $searchlogfile = $searchlogfile_base.$yday;		# the detail searchlog file
    if (-e $searchlogfile) {					# if this file exists
      @report_array = ();
      eval {
        open (SEARCHLOG, $searchlogfile) or die "Cannot open searchlogfile '$searchlogfile' for reading: $!";
        while (<SEARCHLOG>) {
          push @report_array, $_;
        }
        close(SEARCHLOG);
      };
      if ($@){
        log_error("cnsldtrprt12", $@);
        return (99, $@);
      }
      $i = 0;
      while ($report_array[$i]) {
        @row_array = ();
        @row_array = split /:::/, $report_array[$i];
		# row_array [0] is term-keys
		# row_array [1] is search time
		# row_array [2] is search duration
		# row_array [3] is num of results
		# row_array [4] is next or prev
		# row_array [5] is search source
        if ($row_array[1] > $last_consolidate_date) {
          if ($row_array[3] == 0) {				# number of results is not zero
            $usernomatchlogmth_dbfile{$row_array[0]}++;
            $usernomatchlog_dbfile{$row_array[0]}++;
            $nomatchlogmth_dbfile{$row_array[0]}++;
            $nomatchlog_dbfile{$row_array[0]}++;
          } else {							# no matches found - num of results = 0
            $usmnum_of_times = 0;
            $usnum_of_times  = 0;
            $smnum_of_times  = 0;
            $snum_of_times   = 0;
            $usmnext_prev = 0;
            $usnext_prev  = 0;
            $smnext_prev  = 0;
            $snext_prev   = 0;
            if ($usersearchlogmth_dbfile{$row_array[0]}) { 
              ($usmnum_of_times, $usmnext_prev) = unpack("C/A* C/A*", $usersearchlogmth_dbfile{$row_array[0]});
            }
            if ($usersearchlog_dbfile{$row_array[0]}) { 
              ($usnum_of_times, $usnext_prev)   = unpack("C/A* C/A*", $usersearchlog_dbfile{$row_array[0]});
            }
            if ($searchlogmth_dbfile{$row_array[0]}) { 
              ($smnum_of_times, $smnext_prev)   = unpack("C/A* C/A*", $searchlogmth_dbfile{$row_array[0]});
            }
            if ($searchlog_dbfile{$row_array[0]}) { 
              ($snum_of_times, $snext_prev)     = unpack("C/A* C/A*", $searchlog_dbfile{$row_array[0]});
            }
            $usmnum_of_times++;
            $usnum_of_times++;
            $smnum_of_times++;
            $snum_of_times++;
            if ($row_array[4] > 0) {				# if next-prev used
              $usmnext_prev++;
              $usnext_prev++;
              $smnext_prev++;
              $snext_prev++;
            }
            $usersearchlogmth_dbfile{$row_array[0]} = pack("C/A* C/A*", $usmnum_of_times, $usmnext_prev);
            $usersearchlog_dbfile{$row_array[0]}    = pack("C/A* C/A*", $usnum_of_times, $usnext_prev);
            $searchlogmth_dbfile{$row_array[0]}     = pack("C/A* C/A*", $smnum_of_times, $smnext_prev);
            $searchlog_dbfile{$row_array[0]}        = pack("C/A* C/A*", $snum_of_times, $snext_prev);
          }
        }
        $i++;
      }
      if (!$last_search_use_date) { # last record of the first searchlogfile has the last used date
        $last_search_use_date = $row_array[1];
      }
    }
  }

  #
  # delete all the searchlog files older than 7 days
  #
  if ($yday_saved < 7) {
    $yday_saved += 365;
  }
  $yday_saved -= 7;
  for ($loop = 1; $loop <= 28; $loop++) {
    eval {
      $searchlogfile = $searchlogfile_base.$yday_saved;
      unlink($searchlogfile) or die "Cannot delete $searchlogfile: $!";
    };
    if ($yday_saved == 0) {
      $yday_saved = 365;
    } else {
      $yday_saved--;
    }
  }

  #
  # update the user_status_dbfile with last_search_use_date and last_report_update_date
  #   key = user_id + '-' + status_type
  #     status_type = 1 = last_indexed_date
  #     status_type = 2 = last_search_use_date
  #     status_type = 3 = member_status (F = free, S = subscription)
  #     status_type = 4 = config_status (I, IQ, S, IS, IQS)
  #     status_type = 5 = last_report_update_date
  #
  eval {
    use Fcntl;
    tie %user_status_dbfile, $db_package, $USER_STATUS_DB_FILE, O_CREAT|O_RDWR, 0755 or die "Cannot open $USER_STATUS_DB_FILE: $!";
    if ($last_search_use_date) {
      $db_key = $user_id.'-2';
      $user_status_dbfile{$db_key} = $last_search_use_date;
print "<br>error12 - userstatusdbfile - $db_key, $user_status_dbfile{$db_key}\n";
    }
    $db_key = $user_id.'-5';
    $user_status_dbfile{$db_key} = time();
    untie %user_status_dbfile;
  };

  if ($@) {
    log_error ("cnsldtrprt13", $@);
print "<br>error13 $@ \n";
    return (99, $@);
  }

  return (0, "success");
}



######################################################################################



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
    log_error ("p_sendemail1 - cnsldtrprt", $@);
    return (99, $internal_error);
  }
  return(0, "success");

}


1;