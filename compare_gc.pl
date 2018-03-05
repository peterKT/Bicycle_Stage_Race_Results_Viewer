#!/usr/bin/perl -w
use DBI;
use Term::ANSIColor;

#OUTPUT STAGE GC LIST WITH COMPARISON TO 
#PREVIOUS STAGE

print "To identify the event you are interested in, I need to access the database\n";
print "using an account with at least read permissions. Please enter the user name here: \n";  
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

# Get available races

my $query0 = "SELECT table_name FROM information_schema.tables WHERE table_schema='races' AND table_name != 'riders' AND table_name != 'countries' AND table_name != 'teams'";
my $sth = $dbh->prepare($query0);
$sth->execute();

$counter = 1;
print "\n\n";

while (my $row = $sth->fetchrow_arrayref) 
	{	
		$pick = @$row[0];
#		print "The key is $counter and the value is $pick\n";
		$selection{$counter} = $pick;
		print "Choose $counter for this race: $selection{$counter}\n";
		$counter++;
	}
$choice = <STDIN>;
chomp ($choice);

if ( ($choice > 0) && ($choice <= $counter) )
	{
		print "Great! We'll get results for $selection{$choice}\n\n";

$event = $selection{$choice};

# First, set up reasonable values for formatting the names of riders and teams. Some events feature much longer
# names than others.

$longest_name = 0;
$longest_team = 0;
$x = 0;
$y = 0;

my $query3 = "SELECT LENGTH(rider_name), LENGTH(team) FROM $event, riders, teams WHERE $event.rider_id = riders.rider_id AND riders.team_id = teams.team_id";
my $sth = $dbh->prepare($query3);
$sth->execute();

while (my $row = $sth->fetchrow_arrayref) 
	{
		$x = @$row[0];
		$y = @$row[1];
		if ($x > $longest_name) {
		$longest_name = $x;
		}
		if ($y > $longest_team) {
			$longest_team = $y
		}
	}

$name_space = $longest_name + 5;
$team_space = $longest_team + 5;

print "Using $name_space spaces for names and $team_space spaces for teams.\n";

my $query01 = "SELECT COUNT(*) totalColumns FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name='$event' AND TABLE_SCHEMA = 'races'";
my $sth = $dbh->prepare($query01);
$sth->execute();

while (my $row = $sth->fetchrow_arrayref) 
	{
		$total_stages = (@$row[0] - 1) / 2;
	}

$get_another = 'y';

while ($get_another eq 'y') {
# print "The value of get_another is TOP $get_another\n";

print "\nPlease enter a stage number. I will report the GC\n";
print "results and show how each rider\'s standing compares\n";
print "to the previous stage: plus sign for up, minus for down.\n";

print "\nSo go ahead, enter a stage number between 1 and $total_stages.\n";

$stage_no = <STDIN>;
chomp($stage_no);
$previous_stage = $stage_no - 1;

if ($stage_no > 1 && $stage_no < ($total_stages + 1) ) {

print "Great, you want the results for stage $stage_no. Here you go: \n\n";

my $query = "SELECT rider_name, country, team, s$stage_no, t$stage_no, s$previous_stage, riders.rider_id, LENGTH(rider_name), CHAR_LENGTH(rider_name), LENGTH(CONVERT(team USING 'utf8')), CHAR_LENGTH(CONVERT(team USING 'utf8')) FROM riders, countries, teams, $event WHERE s$stage_no != 0 AND riders.rider_id = $event.rider_id AND countries.country_id = riders.country_id AND teams.team_id = riders.team_id ORDER BY s$stage_no";


my $sth = $dbh->prepare($query);

$sth->execute();


print "Results for stage $stage_no. Last number shows change from previous stage.\n\n";
#$name_space = 27;
#$name_space = 40;
#print "Using $name_space for the number of spaces in first column.\n";
#$team_space = 35;
#$team_space = 50;
#print "Using $team_space for the number of spaces in third column.\n";
# Alternative: printf REPORT above

printf "%" . $name_space . "s %8s %" . $team_space . "s %6s %12s %6s %7s\n", "Name","Country","Team","Place", "Time","Prev","Change";

while (my $row = $sth->fetchrow_arrayref) {
	if (@$row[5] > @$row[3])
		{
			$diff = @$row[5] - @$row[3];
			$diff2 = $diff; 	# value for hash only, with no plus sign
			$diff = "+$diff";
		} elsif (@$row[5] < @$row[3]) 
		{
			$diff = @$row[3] - @$row[5];
			$diff = "-$diff";
			$diff2 = $diff;		# value for hash only, with minus sign
		} else {
			$diff = " 0";
			$diff2 = 0;		# value for hash only, use zero not letters
		}
# Create hash with rider ID and value of $diff for use in optional report

	
	$compare_position{@$row[6]} = $diff2;	# assign diff value to hash with rider ID as the key	

# Figure out the number of spaces to assign column 1. Normally $name_space unless diacritics mess it up.

$length_name = @$row[7];
$char_length_name = @$row[8];
if ($length_name == $char_length_name) 
	{
		$this_name_space = $name_space;
	} else {
		$this_name_space = $name_space + ($length_name - $char_length_name);
	}

# Figure out the number of spaces to assign column 3. Normally $name_space unless diacritics mess it up.

$length_team = @$row[9];
$char_length_team = @$row[10];
if ($length_team == $char_length_team) 
	{
		$this_team_space = $team_space;
	} else {
		$this_team_space = $team_space + ($length_team - $char_length_team);
	}

# Alternative: printf REPORT 
if ($diff == 0) {

	printf "%" . $this_name_space . "s %8s %" . $this_team_space . "s %6g %12s %6g    %7s\n", @$row[0], @$row[1], @$row[2], @$row[3], @$row[4], @$row[5], colored($diff,'black');
	} elsif ($diff > 0) {
	printf "%" . $this_name_space . "s %8s %" . $this_team_space . "s %6g %12s %6g    %7s\n", @$row[0], @$row[1], @$row[2], @$row[3], @$row[4], @$row[5], colored($diff,'green');
	} else {
	printf "%" . $this_name_space . "s %8s %" . $this_team_space . "s %6g %12s %6g    %7s\n", @$row[0], @$row[1], @$row[2], @$row[3], @$row[4], @$row[5], colored($diff,'red');
	}

} 


# Use captured hash info to create report sorted in order of position increases or decreases

print "\n\nWould you like the optional report showing results in order of Winners and Losers?\n";
print "Please enter y for yes. Anyother key to exit.\n";
$answer = <STDIN>;
chomp($answer);

if ($answer eq 'y')
  {
	sub by_number {
	
		$compare_position{$b} <=> $compare_position{$a}

		}

print "\n\nGreat. Here are the comparative standings for stage $stage_no. The numbers show\n";
print "change in position from the previous stage. Zero means no change. Negative numbers\n";
print "show losses of position.\n\n";	
 
	
printf "%" . $name_space . "s %8s %" . $team_space . "s %6s \n", "Name","Country","Team","Change";

foreach $elem(sort by_number keys %compare_position) {

	my $query2 = "SELECT rider_name, country, team, LENGTH(rider_name), CHAR_LENGTH(rider_name), LENGTH(CONVERT(team USING 'utf8')), CHAR_LENGTH(CONVERT(team USING 'utf8')) FROM riders, countries, teams WHERE riders.rider_id = $elem AND countries.country_id = riders.country_id AND teams.team_id = riders.team_id";

	my $sth = $dbh->prepare($query2);
	$sth->execute();
	
	while (my $row = $sth->fetchrow_arrayref) 
	{

# Again, fix space confusion when diacritics appear in names.
 
$length_name = @$row[3];
$char_length_name = @$row[4];
if ($length_name == $char_length_name) 
	{
		$this_name_space = $name_space;
	} else {
		$this_name_space = $name_space + ($length_name - $char_length_name);
	}

$length_team = @$row[5];
$char_length_team = @$row[6];
if ($length_team == $char_length_team) 
	{
		$this_team_space = $team_space;
	} else {
		$this_team_space = $team_space + ($length_team - $char_length_team);
	}


#	printf "The sorted-by-value key is $elem which is the ID for %$name_spaces and the value is $compare_position{$elem}\n", @$row[0];

	if ( $compare_position{$elem} > 0 ) {
		printf "%" . $this_name_space . "s %8s %" . $this_team_space . "s" . colored("    +",'green') . "%6s \n", @$row[0], @$row[1], @$row[2], colored($compare_position{$elem},'green');
		} elsif ( $compare_position{$elem} < 0 ) {
	printf "%" . $this_name_space . "s %8s %" . $this_team_space . "s    %6s \n", @$row[0], @$row[1], @$row[2], colored($compare_position{$elem},'red');
		} else {
	printf "%" . $this_name_space . "s %8s %" . $this_team_space . "s     %6s \n", @$row[0], @$row[1], @$row[2], colored($compare_position{$elem}, 'black');
	}
     } # Ends while my $row	
	
   } # Ends foreach $elem

  } else {
	print "Great. So long.\n";
	}


# STAGE ONE HAS NO PREVIOUS STAGE TO COMPARE TO. ONLY REPORTS RESULTS.



} elsif ($stage_no == 1){

print "Great, you want the results for stage $stage_no. Here you go: \n\n";

my $query = "SELECT rider_name, country, team, s$stage_no, t$stage_no, LENGTH(rider_name), CHAR_LENGTH(rider_name), LENGTH(CONVERT(team USING 'utf8')), CHAR_LENGTH(CONVERT(team USING 'utf8')) FROM riders, countries, teams, $event WHERE s$stage_no != 0 AND riders.rider_id = $event.rider_id AND countries.country_id = riders.country_id AND teams.team_id = riders.team_id ORDER BY s$stage_no";

my $sth = $dbh->prepare($query);

$sth->execute();


print "Results for stage $stage_no. \n\n";


# Alternative: printf REPORT (not being used)
printf "%" . $name_space . "s %8s %" . $team_space . "s %6s %12s \n", "Name","Country","Team","Place", "Time";

while (my $row = $sth->fetchrow_arrayref) 
	{	

# Fix spacing

$length_name = @$row[5];
$char_length_name = @$row[6];
if ($length_name == $char_length_name) 
	{
		$this_name_space = $name_space;
	} else {
		$this_name_space = $name_space + ($length_name - $char_length_name);
	}

$length_team = @$row[7];
$char_length_team = @$row[8];
if ($length_team == $char_length_team) 
	{
		$this_team_space = $team_space;
	} else {
		$this_team_space = $team_space + ($length_team - $char_length_team);
	}

# Alternative: printf REPORT (not being used)

	printf "%" . $this_name_space . "s %8s %" . $this_team_space . "s %6g %12s \n", @$row[0], @$row[1], @$row[2], @$row[3], @$row[4];
	}

} else {

print "Sorry, that is not a correct stage number for this event. Please try again.\n";
}

print "Type y for yes if you would like to continue. Any other key to exit\n";

$get_another = <STDIN>;
chomp($get_another);
# print "The value of get_another is BOTTOM $get_another\n";
}

$dbh->disconnect;


	} else {

		print "Sorry... That's not a valid number. Try again\n";	# Pick number of event got bad number
	$dbh->disconnect;	
	}





