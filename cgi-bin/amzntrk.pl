#!/usr/bin/perl 

BEGIN {
   $|=1;
   use CGI::Carp('fatalsToBrowser');
#   use CGI::Carp qw(carpout);
#   open (ERRORLOG, ">>/home/grepinco/public_html/cgi-bin/log/amzntrkerr.txt")
#       or die "Unable to append to errorlog: $!\n";
#   carpout(*ERRORLOG);
}

$|=1;    # autoflush

  use Fcntl;
  use CGI;
  package main;

  my $query = new CGI;
  my $user_id     = $query->param('uid');	# user id
  my $ref_id      = $query->param('rid');       # referral id
  my $trknum      = $query->param('trknum');	# search keyword
  my $url         = $query->param('url');       # url
  my $b           = $query->param('b');         # beneficiary

log_query();

print "Location: $url\n\n";

exit;



sub log_query {

  my @line = ();

  use Fcntl;

  push(@line, 'amazon-c',
              $user_id || '-',
              $ref_id || '-',
              $trknum || '-',
              $b || '-',
              localtime time() || '-');

  #
  # write log in batch
  #

  eval {
    $pid = fork();
    if ($pid == 0) {
      close STDIN;
      close STDOUT;
      close STDERR;

      use Fcntl ':flock';        # import LOCK_* constants
#      if ($user_id) {
#        $LOG_FILE = '/home/grepinco/public_html/cgi-bin/users/users/$user_id/search/amznclk.txt';
#      } else {
        $LOG_FILE = '/home/grepinco/public_html/cgi-bin/log/amznclk.txt';
#      }

      open(LOG, ">>$LOG_FILE") or die "Cannot open logfile '$LOG_FILE' for writing: $!";
      flock(LOG, LOCK_EX);
      seek(LOG, 0, 2);
      print LOG join(':::', @line).":::\n";
      flock(LOG, LOCK_UN);
      close(LOG);

    } elsif (!defined $pid) {
      die "fork failed during logquery in amzntrk";
    }
  };

#  if ($@){
#    log_error("logquery", $@);
#  }

}
