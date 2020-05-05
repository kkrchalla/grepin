# Grepin Search and Services - userconf.pl
#$rcs = ' $Id: userconf.pl,v 1.0 2004/03/30 12:00:00 Exp $ ' ;

# Copyright (C) Grepin Search and Services <contactme@grepin.com>
# 

my $INDEX_STATUS = 'N';

my $MEMBER_STATUS = 'F';

my $INSTALL_DIR       = $SRCH_USER_DIR.':::grepin-userid:::';
my $TEMPLATE_DIR      = $INSTALL_DIR.'/templates/';
my $RESULTS_TEMPLATE  = $TEMPLATE_DIR.'resultspage.html';
my $SEARCH_TEMPLATE   = $TEMPLATE_DIR.'search.html';
my $NO_MATCH_TEMPLATE = $TEMPLATE_DIR.'nomatch.html';

my $TMP_DIR           = $INSTALL_DIR.'/temp/';
my $NO_INDEX_FILE     = $INSTALL_DIR.'/noindex.txt';
my $STOPWORDS_FILE    = $INSTALL_DIR.'/stopwords.txt';

my $LOG_DIR           = $INSTALL_DIR.'/reports/';

my $DATA_DIR 	    = $INSTALL_DIR.'/data/';
my $UPDATE_FILE 	    = $DATA_DIR.'update';
my $INV_INDEX_DB_FILE = $DATA_DIR.'inv_index';
my $DOCS_DB_FILE      = $DATA_DIR.'docs';
my $URLS_DB_FILE      = $DATA_DIR.'urls';
my $SIZES_DB_FILE     = $DATA_DIR.'sizes';
my $TERMS_DB_FILE     = $DATA_DIR.'terms';
my $DF_DB_FILE        = $DATA_DIR.'df';
my $TF_DB_FILE        = $DATA_DIR.'tf';
my $CONTENT_DB_FILE   = $DATA_DIR.'content';
my $DESC_DB_FILE      = $DATA_DIR.'desc';
my $TITLES_DB_FILE    = $DATA_DIR.'titles';
my $DATES_DB_FILE     = $DATA_DIR.'dates';

my $INV_INDEX_TMP_DB_FILE = $DATA_DIR.'inv_index_tmp';
my $DOCS_TMP_DB_FILE      = $DATA_DIR.'docs_tmp';
my $URLS_TMP_DB_FILE      = $DATA_DIR.'urls_tmp';
my $SIZES_TMP_DB_FILE     = $DATA_DIR.'sizes_tmp';
my $TERMS_TMP_DB_FILE     = $DATA_DIR.'terms_tmp';
my $CONTENT_TMP_DB_FILE   = $DATA_DIR.'content_tmp';
my $DESC_TMP_DB_FILE      = $DATA_DIR.'desc_tmp';
my $TITLES_TMP_DB_FILE    = $DATA_DIR.'titles_tmp';
my $DATES_TMP_DB_FILE     = $DATA_DIR.'dates_tmp';

my $ROBOT_AGENT = 'grepin';

my $HTTP_FOLLOW_COMMENT_LINKS = 0;
my @HTTP_CONTENT_TYPES = ('text/html', 'text/plain', 'application/pdf', 'application/msword');

my $HTTP_DEBUG = 1;

my %EXT_FILTER = (
	   "pdf" => "/usr/bin/pdftotext FILENAME -",
	   "doc" => "/usr/bin/antiword FILENAME",
	   "PDF" => "/usr/bin/pdftotext FILENAME -",
	   "DOC" => "/usr/bin/antiword FILENAME"
);
my @EXT = ("html", "HTML", "htm", "HTM", "shtml", "SHTML", "pdf", "PDF", "doc", "DOC");
my $RESULTS_PER_PAGE = 10;
my $MAX_RESULTS = 0;

my $LOW_MEMORY_INDEX = 0;
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

my $PERCENTAGE_RANKING = 1;
my $TITLE_WEIGHT = 5;
my $META_WEIGHT = 5;
my %H_WEIGHT;
   $H_WEIGHT{'1'} = 5;	# headline <h1>...</h1>
   $H_WEIGHT{'2'} = 4;
   $H_WEIGHT{'3'} = 3;
   $H_WEIGHT{'4'} = 1;
   $H_WEIGHT{'5'} = 1;
   $H_WEIGHT{'6'} = 1;	# headline <h6>...</h6>
my $MULTIPLE_MATCH_BOOST = 1;

my $LOG = 1;


# Date format for the result page. %Y = year, %m = month, %d = day,
# %H = hour, %M = minute, %S = second. On a Unix system use 
# 'man strftime' to get a list of all possible options.
my $DATE_FORMAT = "%Y-%m-%d";

my $NEXT_PAGE = 'Next';
my $PREV_PAGE = 'Prev';

my $IGNORED_WORDS = '<p>The following words are either too short or very common and were
	not included in your search: <strong><WORDS></strong></p>';

my $SEARCH_URL = $SRCH_DIR.'search';

my $CONF_VAR006 =1;
my $CONF_VAR007 =1;
my $CONF_VAR008 =1;
my $CONF_VAR009 =1;
my $CONF_VAR010 =1;


1;
