#!/usr/bin/perl
#$rcs = ' $Id: indexlogfile.pl,v 1.0 2004/03/30 00:00:00 Exp $ ' ;

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

  my $uid = $query->param('uid');
  if (!$uid){
    print "User Id is not supplied... Please supply a user id...";
    exit;
  }

  my $INDEXLOGFILE = '/home/grepinco/public_html/cgi-bin/search/users/'.$uid.'/indexlog.txt';

  print "<font face=courier>\n";

  print "<br><b><u><font size=3> Index Log for User-Id - $uid </u></b><font size=0> \n";
  eval {
    open(INDXFILE, $INDEXLOGFILE) or (die "Cannot open '$INDEXLOGFILE': $!");
    while (<INDXFILE>) {
      chomp;
      print "<br>$_ \n";
    }
    close(INDXFILE);
  };
  if ($@){
    print "$@ \n";
  }


  print "<br><br><br><b> THE END <b> \n";


  exit;
