# Grepin Search and Services - userconf.pl
#$rcs = ' $Id: userconf.pl,v 1.0 2004/03/30 12:00:00 Exp $ ' ;

# Copyright (C) Grepin Search and Services <contactme@grepin.com>
# 

sub v_userconf {

  my $INDEX_STATUS = 'N';
  my $MEMBER_STATUS = 'F';
  my $HTTP_FOLLOW_COMMENT_LINKS = 0;
  my @HTTP_CONTENT_TYPES = ('text/html', 'text/plain', 'application/pdf', 'application/msword');
  my %EXT_FILTER = (
	   "pdf" => "/usr/bin/pdftotext FILENAME -",
	   "doc" => "/usr/bin/antiword FILENAME",
	   "PDF" => "/usr/bin/pdftotext FILENAME -",
	   "DOC" => "/usr/bin/antiword FILENAME"
  );
  my @EXT = ("html", "HTML", "htm", "HTM", "shtml", "SHTML", "pdf", "PDF", "doc", "DOC");
  # Date format for the result page. %Y = year, %m = month, %d = day,
  # %H = hour, %M = minute, %S = second. On a Unix system use 
  # 'man strftime' to get a list of all possible options.
  my $CONTEXT_SIZE = 10000;
  my $CONTEXT_EXAMPLES = 3;
  my $CONTEXT_DESC_WORDS = 10;
  my $DESC_WORDS = 25;
  my $MINLENGTH = 3;
  my $SPECIAL_CHARACTERS = 1;
  my $STEMCHARS = 0;
  my $IGNORE_TEXT_START = '<!--ignore-grepin-start-->';
  my $IGNORE_TEXT_END = '<!--ignore-grepin-end-->';
  my $MAX_TITLE_LENGTH = 80;
  my $NEXT_PAGE = 'Next';
  my $PREV_PAGE = 'Prev';
  my $HTTP_MAX_PAGES = 5000;
  my $INDEX_URLS = 0;
  my $INDEX_NUMBERS = 0;

  return ($INDEX_STATUS, $MEMBER_STATUS, $HTTP_FOLLOW_COMMENT_LINKS, @HTTP_CONTENT_TYPES, %EXT_FILTER, @EXT, $CONTEXT_SIZE, $CONTEXT_EXAMPLES, $CONTEXT_DESC_WORDS, $DESC_WORDS, $MINLENGTH, $SPECIAL_CHARACTERS, $STEMCHARS, $IGNORE_TEXT_START, $IGNORE_TEXT_END, $MAX_TITLE_LENGTH, $NEXT_PAGE, $PREV_PAGE, $HTTP_MAX_PAGES, $INDEX_URLS, $INDEX_NUMBERS);

}

1;