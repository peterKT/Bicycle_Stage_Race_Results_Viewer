#!/usr/bin/perl

# YOU MUST RUN create_results_folder.pl before you run this.
# That will create a folder in your /tmp directory with name = race name.
# Then put into the folder a copy of the stage one results, formatted as per directions and named stage1.csv.
# This program will populate needed tables with info from that file.
# To use, go to the directory containing this
# program and type: ./setup_tables.pl 

# NOTE: This utility only works on stage1.csv and is used purely for preliminary work: adding new rider names,
# adding countries and teams not seen before, updating rider's team membership, and preparing a results
# table.


use DBI;

print "To populate the base tables with names, countries and teams not already available,\nI need to know a MySQL user with permissions\n";
print "Please enter the admin name here: \n";  
$admin_name = <STDIN>;
chomp ($admin_name);
print "\nNow please provide the password: \n";
$admin_pw = <STDIN>;
chomp ($admin_pw);


print "Great. Give me a sec, I will try using $admin_name and $admin_pw.\n";

my $server = 'localhost';
my $db = 'races';
my $username = $admin_name;
my $password = $admin_pw;

my $dbh = DBI->connect("dbi:mysql:$db:$server", $username, $password);

open GET_RACENAME, "<", "/tmp/races/race_name.txt";
$race_name = <GET_RACENAME>;
print "Just a check to make sure we got the path right: /tmp/races/$race_name\n";
close GET_RACENAME;

# This section to correct race results table which was incomplete in version 3.0

print "Great. We are setting up a results table for $race_name.\n";

# This is wrong. stage columns must be added by data_upload.pl

#my $query0 = "CREATE TABLE $race_name (rider_id SMALLINT(4) UNSIGNED NOT NULL, total_stages SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0', s1 SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0', t1 TIME, PRIMARY KEY (rider_id) )";

my $query0 = "CREATE TABLE $race_name (rider_id SMALLINT(4) UNSIGNED NOT NULL, total_stages SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0', PRIMARY KEY (rider_id) )";


my $sth = $dbh->prepare($query0);

$sth->execute();


$counter = 0;

# Now populate the riders, countries, teams tables as needed

open GET_RIDERS, "<", "/tmp/races/$race_name/stage1.csv";
open WRITE_RIDERS, ">", "/tmp/races/rider_names.txt";

foreach (<GET_RIDERS>) # Build an array @array3 consisting of rider names 
{
	chomp;
	@array2 = split /\t/, $_ ; # Capture one line of text from the file 
	$delete_me = shift(@array2); # Get rid of the position number
	foreach $elem(@array2) 
	{
	if ( $elem =~ /^\(/ ) {
	push(@array3, "\n");
	last;	# Stop right here at the nationality field.
	  } else {
	push(@array3, "$elem ");
	  }
	}
}
	print WRITE_RIDERS @array3;
	print WRITE_RIDERS "\n";

close GET_RIDERS;
close WRITE_RIDERS;

	
open CHANGE_RIDERS, ">", "/tmp/races/new_names.txt";
open WRITE_RIDERS, "<", "/tmp/races/rider_names.txt";

# QUICK, GET RID OF THAT UNWANTED SPACE AT LINE END

foreach (<WRITE_RIDERS>)
{
	  s/ \n/\n/;
	  print CHANGE_RIDERS $_; 
}	

close WRITE_RIDERS;
close CHANGE_RIDERS;

# Now do the same for rider nationalities

open GET_RIDERS, "<", "/tmp/races/$race_name/stage1.csv";
open WRITE_NATS, ">", "/tmp/races/rider_nats.txt";

foreach (<GET_RIDERS>) # Build an array @array4 consisting of rider nationalities 
{
	chomp;
	@array4 = split /\t/, $_ ; # Capture one line of text from the file 
	foreach $elem(@array4) 
	{
	if ( $elem =~ /^\(/ ) {
	push(@array5, "$elem\n");
	last;	# Stop right here at the nationality field. No team info.
	  }
	  
	}
}
	print WRITE_NATS @array5;

close GET_RIDERS;
close WRITE_NATS;

# Get rid of duplicates. Especially important once we start adding more events.

system 'sort -u /tmp/races/rider_nats.txt > /tmp/races/new_nats.txt';

my $query4 = "CREATE TABLE countries_temp LIKE countries";
my $sth = $dbh->prepare($query4);
$sth->execute();

my $query5 = "LOAD DATA INFILE '/tmp/races/new_nats.txt' INTO TABLE countries_temp(country)";
my $sth = $dbh->prepare($query5);
$sth->execute();

# Next, take new country names and add them to the database, making sure to ignore duplicates.

my $query6 = "INSERT INTO countries(country) SELECT country FROM countries_temp  where country NOT IN (SELECT country FROM countries)";

my $sth = $dbh->prepare($query6);
$sth->execute();

my $query7 = "DROP TABLE countries_temp";
my $sth = $dbh->prepare($query7);
$sth->execute();

# Now do the same for rider teams

open GET_RIDERS, "<", "/tmp/races/$race_name/stage1.csv";
open WRITE_TEAMS, ">>", "/tmp/races/rider_teams.txt";


# Create a file containing team names. 
# Note: Annoying empty spaces cannot be counted easily. Something is 
# hidden in them that avoids detection. This method however works around that.  

foreach (<GET_RIDERS>) # Build an array @array6 consisting of team names  
{
	chomp;
	@array6 = split /\t/, $_; # Capture line of text from the file 
	$blanks = 0;
	$counter = 0;
	$counter_one = 0;
	$counter_two = 0;
	@array7 = ();
	foreach $elem(@array6) 
	{

		if ( $elem =~ /^\(/ ) 
		 { 
			$counter_one = $counter;
		 } elsif ( $elem =~ /:/ )
		 {	
			$counter_two = $counter;
		 } elsif ( $elem eq "" )
		 {	$blanks++;
		 } elsif ( ($elem =~ /\w+/) || ($elem =~ /\//) || ($elem =~ /-/) ){
		 } else {
			$blanks++;
			# Needed because eq "" does not catch empties.
		}	
	
	$counter++;	
	}

	$counter_three = $counter_one + 1;
	if ($counter_two != 0) {	
	$counter_four = $counter_two - 1;
		} elsif ($counter > $blanks) {
	$counter_four = (($counter - $blanks) - 1);
		} else { print "ERROR HERE\n";
		}
	
   
	@array7 = @array6[$counter_three..$counter_four];


	$string = join( ' ', @array7 );
	
	print WRITE_TEAMS $string; 	
	print WRITE_TEAMS "\n";
}

close GET_RIDERS;
close WRITE_TEAMS;

# Fix spacing that can mess things up and also replace any dashes with hyphens. 
# Dashes get misunderstood, spacewise.

open READ_TEAMS, "<", "/tmp/races/rider_teams.txt";
open WRITE_TEAMS_CLEAN, ">>", "/tmp/races/rider_teams_clean.txt";

foreach (<READ_TEAMS>)
{
	chomp;
	s/\s$//;
	s/–/-/;
	$clean = $_ ;
	print WRITE_TEAMS_CLEAN $clean . "\n";
}

close READ_TEAMS;
close WRITE_TEAMS_CLEAN;

# Get rid of duplicates. 
system 'sort -u /tmp/races/rider_teams_clean.txt > /tmp/races/no_duplicate_teams.txt';

my $query8 = "CREATE TABLE teams_temp LIKE teams";
my $sth = $dbh->prepare($query8);
$sth->execute();

my $query9 = "LOAD DATA INFILE '/tmp/races/no_duplicate_teams.txt' INTO TABLE teams_temp(team)";
my $sth = $dbh->prepare($query9);
$sth->execute();

# Next, take new team names and add them to the database, making sure to ignore those already
# in the database. This will be especially important later if more races are added.
# The rider table along with the tables for nationalities and team names will
# grow as more information becomes available, and can be used for different events
# since the event results tables themeselves link to all three tables through the unique rider ID.
# But the only way to add to them is to scan a stage1.csv file to collect info on riders
# and teams, and many of these may already have been set up. Repeat this approach
# for riders and countries.


my $query10 = "INSERT INTO teams(team) SELECT team FROM teams_temp where team NOT IN (SELECT team FROM teams)";

my $sth = $dbh->prepare($query10);
$sth->execute();

my $query11 = "DROP TABLE teams_temp";
my $sth = $dbh->prepare($query11);
$sth->execute();



# Now put the names into the riders table. Checks for duplicates.

my $query12 = "CREATE TABLE riders_temp LIKE riders";
my $sth = $dbh->prepare($query12);
$sth->execute();

my $query13 = "LOAD DATA INFILE '/tmp/races/new_names.txt' INTO TABLE riders_temp(rider_name)";
my $sth = $dbh->prepare($query13);
$sth->execute();

# Next, take new rider names and add them to the database, making sure to ignore duplicates.
# This way, after team and nationality info is added, the rider table can grow over time, race by race. Note 
# that we will check for duplicates using utf8_bin collation to avoid matching on names that do
# not have exactly the same diacritics. If the name already exists but with different/missing/additional accents
# it will be ignored and the new version used instead. Otherwise havoc ensues because the slightly
# different spelling of the name will find no match in the results files.

my $query14 = "INSERT INTO riders(rider_name) SELECT rider_name FROM riders_temp  where rider_name COLLATE utf8_bin NOT IN (SELECT rider_name FROM riders)";

my $sth = $dbh->prepare($query14);
$sth->execute();

my $query15 = "DROP TABLE riders_temp";
my $sth = $dbh->prepare($query15);
$sth->execute();

#Delete temporary files used to populate tables

unlink 
("/tmp/races/rider_names.txt",
# "/tmp/races/new_names.txt", 
"/tmp/races/rider_nats.txt",
"/tmp/races/rider_teams.txt");


# Now update the rider table with each person's country ID and team ID


my $query16 = "SELECT country_id,country from countries INTO OUTFILE '/tmp/races/countries.txt'";

my $sth1 = $dbh->prepare($query16);

$sth1->execute();


my $query17 = "SELECT rider_id,rider_name from riders INTO OUTFILE '/tmp/races/riders.txt'";

my $sth2 = $dbh->prepare($query17);

$sth2->execute();


my $query3 = "SELECT team_id,team from teams INTO OUTFILE '/tmp/races/teams.txt' CHARACTER SET utf8";

my $sth3 = $dbh->prepare($query3);

$sth3->execute();


# new_names.txt is used to populate the riders table. It derives these names from stage1.csv
# The names are then dumped into riders.txt along with the rider ID they were assigned.
# Thus riders.txt can be relied on to contain exactly the same names, character-for-character, as
# found in stage1.csv even though there may be multiple slightly different versions (that will 
# be ignored).


open RESULTS, "<", "/tmp/races/$race_name/stage1.csv";
open COUNTRIES, "</tmp/races/countries.txt";
open NTUPLOAD, ">/tmp/races/upload.txt";


sub obtain_rider_IDs {

open RIDERS, "</tmp/races/riders.txt";


foreach (<RIDERS>)
{
	chomp;
	@array2 = split /\t/, $_ ; 
	$rider_key = $array2[1];
#	$lc_rider_key = $rider_key;
#	$lc_rider_key =~ tr/A-Z/a-z/;
	$rider_value = $array2[0];
	$rider_id{$rider_key} = $rider_value;
}
close RIDERS;
}	# End routine definition


# Start by figuring out the country_id. We need this to populate the rider file.

sub get_nat_id {
	foreach (<COUNTRIES>)
	{
	#Don't forget to chomp. Otherwise you will get an extra line return.

	chomp;
	@nat_array = split /\t/, $_ ;
	$key = $nat_array[1];
	$value = $nat_array[0];
	$nat_hash{$key} = $value;
	}
}

# Same for teams. Needed to insert team ID into rider file.
sub get_team_id {
	open TEAMS, "</tmp/races/teams.txt";
	foreach (<TEAMS>)
	{
		chomp;
		@team_array = split /\t/, $_;
		$team_key = $team_array[1];
		$lc_team_key = $team_key;
		$lc_team_key =~ tr/A-Z/a-z/;
		$team_value = $team_array[0];
		$team_hash{$lc_team_key} = $team_value;

	}
	close TEAMS;
}

&obtain_rider_IDs;
&get_nat_id;
&get_team_id;

# Now that hashes are available matching text strings with unique id identifiers, we
# can go back through a line-by-line examination of stage one results (the most inclusive)
# and match names of riders, countries, and teams with their IDs. We will use this to 
# update the already loaded but incomplete rider table with each individual's country and team ID.

$errors = 0;

foreach (<RESULTS>) # Build an array @array2 consisting of rider names 
{
	@array1 = ();
	chomp;
	@array1 = split /\t/, $_; # Capture line of text from the file 
	@array2 = ();
	$counter = 0;
	$position = shift(@array1); # store the position number
	foreach $elem(@array1) {
	
		if ( $elem =~ /^\(/ ) {
		last;	# Stop right here at the nationality field.
	  	} else {
		push(@array2, "$elem");
		$counter++;
		}
	}

# Got name. 

# Number of elements in the name

$name_elements = $counter;

$full_name = join " ", @array2;	# Put the name back together for later use

#} PUT ME AT THE END 

# Complete rider name (as used in the hash) is now in $full_name

	$counter = 0;
	$counter_one = 0;
	$counter_two = 0;
	$blanks = 0;
	  $rider_no = $rider_id{$full_name};
	  if (not defined ($rider_no) )
		{
		  print "Rider ID not defined for results file line $position\n";
		  print "Fix and re-run me.\n";
		  $errors++;		
		}
	  print NTUPLOAD "$rider_no,";   # Put rider ID
	  foreach $elem(@array1) 
	  {
	    if( ($elem =~ /\w+/) || ($elem =~ /\//) || ($elem =~ /-/) || ($elem =~ /^\(/) || ($elem =~ /:/) )
	      { 
		if ($elem =~ /^\(/ ) 
		  {
		    $nat = $elem;
		    $counter_one = $counter;	
		  } 
		  elsif ($elem =~ /:/)
		   {
		     $counter_two = $counter;
		   }

	        $counter++; 	

	      } 

	    elsif ( $elem eq "" )	
	     {	
			$counter++;
			$blanks++;
	     }

	    else {
			$counter++;
			$blanks++;
			
			# Needed because eq "" does not catch empties.
		}	


	  }
	
	$counter_three = $counter_one + 1;
	if ($counter_two != 0) {	
	$counter_four = (($counter_two - 1) - $blanks);
		} elsif ($counter > $blanks) {
	$counter_four = (($counter - 1) - $blanks);
		} else { print "Something is wrong\n";}	

   
	@array8 = @array1[$counter_three..$counter_four];


	$team = join( ' ', @array8 );
	$lc_team = $team;
	$lc_team =~ tr/A-Z/a-z/;
	# Get rid of those nasty dashes
	$lc_team =~ s/–/-/;



	  $nat_id =  $nat_hash{$nat};
	  if (not defined ($nat_id) )
		{
		  print "Country ID not defined for results file line $position\n";
		  print "Fix and re-run me.\n";
		  $errors++;
		}
	  print NTUPLOAD "$nat_id,"; # Get country ID	
	  $team_id = $team_hash{$lc_team};
	  if (not defined ($team_id) )
		{
		  print "Team ID from hash with key value = $lc_team not defined for results file line $position\n";
		  print "Fix and re-run me.\n";
		  $errors++;
		}
	
	  print NTUPLOAD "$team_id\n";	
	
}	# End for each line of the RESULTS file


close RESULTS;
close COUNTRIES;
close NTUPLOAD;

if ($errors == 0) {

#unlink ("/tmp/races/countries.txt","/tmp/races/riders.txt","/tmp/races/teams.txt");

unlink ("/tmp/races/countries.txt","/tmp/races/teams.txt");

# Now SQL query to update rider table using the handy upload.txt file.
#Then go ahead and load stage results.

my $query19 = "CREATE TABLE riders_temp (rider_id SMALLINT(4) UNSIGNED NOT NULL, country_id SMALLINT(4) UNSIGNED NOT NULL,  team_id SMALLINT(4) UNSIGNED NOT NULL, PRIMARY KEY (rider_id) )";
my $sth = $dbh->prepare($query19);
$sth->execute();


my $query20 = "LOAD DATA INFILE '/tmp/races/upload.txt' INTO TABLE riders_temp FIELDS TERMINATED BY ',' (rider_id,country_id,team_id)";
my $sth = $dbh->prepare($query20);
$sth->execute();

my $query21 = "UPDATE riders,riders_temp SET riders.country_id = riders_temp.country_id WHERE riders.rider_id = riders_temp.rider_id";
my $sth = $dbh->prepare($query21);
$sth->execute();

# Because the team ID is newly created from stage1.csv, it effectively updates previously entered
# team IDS for every rider in the event, taking care of cases where riders may have switched teams
# since last event was processed. Also works in reverse (older events added now will show correct
# team membership at time of that event).

my $query22 = "UPDATE riders,riders_temp SET riders.team_id = riders_temp.team_id WHERE riders.rider_id = riders_temp.rider_id";
my $sth = $dbh->prepare($query22);
$sth->execute();


my $query23 = "DROP TABLE riders_temp";
my $sth = $dbh->prepare($query23);
$sth->execute();

# Just in case we had any blank lines in the upload file

my $query24 = "DELETE FROM riders WHERE rider_name=\"\"";
my $sth = $dbh->prepare($query24);
$sth->execute();

$dbh->disconnect;

} else {

print "You have $errors errors. Fix and re-run setup_tables.pl.\n";
$dbh->disconnect;
}
