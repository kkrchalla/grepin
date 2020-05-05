#!/usr/bin/perl
#$rcs = ' $Id: logfiles.pl,v 1.0 2004/03/30 00:00:00 Exp $ ' ;

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

  my $CRELOGFILE = '/home/grepinco/public_html/cgi-bin/log/creuserlog.txt';
  my $SRCLOGFILE = '/home/grepinco/public_html/cgi-bin/log/sourcelog.txt';
  my $TRMLOGFILE = '/home/grepinco/public_html/cgi-bin/log/terminatorlog.txt';
  my $USTLOGFILE = '/home/grepinco/public_html/cgi-bin/log/userstatlog.txt';

  print "<font face=courier>\n";

  print "<br><b><u><font size=3> Create User Log </u></b><font size=0> \n";
  eval {
    open(CREFILE, $CRELOGFILE) or (die "Cannot open '$CRELOGFILE': $!");
    while (<CREFILE>) {
      chomp;
      print "<br>$_ \n";
    }
    close(CREFILE);
  };
  if ($@){
    print "$@ \n";
  }

  print "<br><br><br><b><u><font size=3> Source Log </u></b><font size=0> \n";
  eval {
    open(SRCFILE, $SRCLOGFILE) or (die "Cannot open '$SRCLOGFILE': $!");
    while (<SRCFILE>) {
      chomp;
      print "<br>$_ \n";
    }
    close(SRCFILE);
  };
  if ($@){
    print "$@ \n";
  }

  print "<br><br><br><b><u><font size=3> Terminator Log </u></b><font size=0> \n";
  eval {
    open(TRMFILE, $TRMLOGFILE) or (die "Cannot open '$TRMLOGFILE': $!");
    while (<TRMFILE>) {
      chomp;
      print "<br>$_ \n";
    }
    close(TRMFILE);
  };
  if ($@){
    print "$@ \n";
  }

  print "<br><br><br><b><u><font size=3> User Status Log </u></b><font size=0> \n";
  eval {
    open(USTFILE, $USTLOGFILE) or (die "Cannot open '$USTLOGFILE': $!");
    while (<USTFILE>) {
      chomp;
      print "<br>$_ \n";
    }
    close(USTFILE);
  };
  if ($@){
    print "$@ \n";
  }

  print "<br><br><br><b> THE END <b> \n";


  exit;