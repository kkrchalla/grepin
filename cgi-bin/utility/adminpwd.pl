#!/usr/bin/perl
#$rcs = ' $Id: adminpwd.pl,v 1.0 2004/03/30 00:00:00 Exp $ ' ;

  BEGIN {
     $|=1;
     use CGI::Carp('fatalsToBrowser');
  }

  # Grepin Search and Services
  # Copyright (C) 2004 Grepin Search and Services <contact@grepin.com>

  {
    $0 =~ /(.*)(\\|\/)/;
    push @INC, $1 if $1;
  }

  use Fcntl;
  use CGI;

  package main;

  my $query = new CGI;

  print "Content-Type: text/html\n\n";

  my $password = $query->param('pwd');
  if ($password ne 'mzlapqnxksowbcjdie'){
    print "You are not authorized to invoke this program.\n";
    exit;
  }

  my $email_id = $query->param('email');

   #admin password = @.{[(yday + 10)+log(email_length)]*email_length}.ema.{[(yday + 10)-log(email_length)]*email_length}
  my $yday = (localtime time())[7];
     $yday += 10;
  my $email_length = length $email_id;
  my $log_length = int (log ($email_length));
  my $first_part = ($yday + $log_length) * $email_length;
  my $last_part  = ($yday - $log_length) * $email_length;
  my $admin_pwd  = '@'.$first_part.substr($email_id,0,3).$last_part;

  print "$admin_pwd \n";

  exit;
