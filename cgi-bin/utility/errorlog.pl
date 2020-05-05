#!/usr/bin/perl
#$rcs = ' $Id: errorlog.pl,v 1.0 2004/03/30 00:00:00 Exp $ ' ;

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

  my $ERRLOGFILE = '/home/grepinco/public_html/cgi-bin/log/errorlog.txt';
  my $SRCLOGFILE = '/home/grepinco/public_html/cgi-bin/log/srcherrlog.txt';
  my $WEBLOGFILE = '/home/grepinco/public_html/cgi-bin/log/webscrerr.txt';

  print "<font face=courier>\n";

  print "<br><b><u><font size=3> Error Log - errorlog.txt </u></b><font size=0> \n";
  eval {
    open(ERRFILE, $ERRLOGFILE) or (die "Cannot open '$ERRLOGFILE': $!");
    while (<ERRFILE>) {
      chomp;
      if ((substr($_,0,1) ne '[') || (substr($_,25,2) ne '] ')) {
        print "<br>$_ \n";
      }
    }
    close(ERRFILE);
  };
  if ($@){
    print "$@ \n";
  }

  print "<br><br><br><b><u><font size=3> Search Error Log - srcherrlog.txt </u></b><font size=0> \n";
  eval {
    open(SRCFILE, $SRCLOGFILE) or (die "Cannot open '$SRCLOGFILE': $!");
    while (<SRCFILE>) {
      chomp;
      if ((substr($_,0,1) ne '[') || (substr($_,25,2) ne '] ')) {
        print "<br>$_ \n";
      }
    }
    close(SRCFILE);
  };
  if ($@){
    print "$@ \n";
  }

  print "<br><br><br><b><u><font size=3> Web Scr Error Log - webscrerr.txt </u></b><font size=0> \n";
  eval {
    open(WEBFILE, $WEBLOGFILE) or (die "Cannot open '$WEBLOGFILE': $!");
    while (<WEBFILE>) {
      chomp;
      if ((substr($_,0,1) ne '[') || (substr($_,25,2) ne '] ')) {
        print "<br>$_ \n";
      }
    }
    close(WEBFILE);
  };
  if ($@){
    print "$@ \n";
  }

  print "<br><br><br><b> THE END <b> \n";


  exit;