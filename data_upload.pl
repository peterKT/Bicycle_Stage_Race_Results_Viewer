#!/usr/bin/perl -w
use DBI;

#UPLOAD DATA
print "To identify the event you want to upload stage result info for,\nI need to access the database\n";
print "using an account with write permissions. Please enter the user name here: \n";  
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

if ( ($choice > 0) && ($choice <= $counter) ) {

print "Great! Everything is ready for $selection{$choice}\n\n";

$race_name = $selection{$choice};


# Figure out how many stages there are

 $figure_out = 1;
 $stages = 0;

while ($figure_out < 23)
 {
	$filename = "/tmp/races/$race_name/stage$figure_out.csv";
	if (-e $filename) {
	@ARGV = glob "/tmp/races/$race_name/stage$figure_out.csv" or die "Could not open file stage$figure_out.csv";
	$^I = ".bak";

	while (<>) 
	{
		s/ /	/g;
		print;
	}





	  $stages++;
	}	 
	$figure_out++;
 }

print "The number of stages is $stages\n";


#------------------------------------ORIGINAL CODE HERE


sub obtain_rider_IDs {

open RIDERS, "</tmp/races/riders.txt";


# IF YOU SEE ERRORS, check this file. The truncated name strings must match the names
# imported with the daily results. They use the same formula to create string matches,
# so they should be equal, but stray odd characters or spaces will mess things up.

	foreach (<RIDERS>)
		{
		chomp;

		@array0 = split /\t/, $_ ;
		$name_key = $array0[1];
		print "I got a name key of $name_key\n";
		$value = $array0[0];
		print "And the number being used for value is $value\n";
		$rider_id{$name_key} = $value;
		print "That gives a rider ID of $rider_id{$name_key}\n";
		}
close RIDERS;

}


sub convert_to_seconds {
	$time = $array[-1];
	@time2 = split /:/, $time;
	$hour = $time2[0];
	$min = $time2[1];
	$sec = $time2[2];
	$total_seconds = (3600 * $hour) + (60 * $min) + $sec;
	}

sub convert_to_date {
	$time = $a;
	$hour = int($time / 3600);
	$time = $time - ($hour * 3600);
	$min = int($time / 60);
	$sec = $time - ($min * 60);
	$date = join ":", $hour, $min, $sec;
	}

&obtain_rider_IDs;

$counter = 0;
$errors = 0;
$upload_file_no = 1;


# This refers to the stage results file you are using as an argument
# foreach (<>) will look at this file line by line

while ( $upload_file_no <= $stages )

{
open STAGES, "</tmp/races/$race_name/stage" . $upload_file_no . ".csv";

$stage_no = $upload_file_no;
$counter = 0;

foreach (<STAGES>) 
{

# Take each rider name (in full) and try to match it with each name in the rider dictionary (new_names.txt)

	@array = ();
	chomp;
	@array = split /\t/, $_; # Capture line of text from the file 

	@array2 = ();
	$elements = 0;
	$position = shift(@array); # store the position number
	foreach $elem(@array) {
	
		if ( $elem =~ /^\(/ ) {
		last;	# Stop right here at the nationality field.
	  	} else {
		push(@array2, "$elem");
		$elements++;
		}
	}

# Got name. 

# Number of elements in the name

#	$name_elements = $elements;

	$full_name = join " ", @array2;	# Put the name back together for later use

	$rider_no = $rider_id{$full_name};



	if (not defined ($rider_no) ) {
				
			 print "\n\nRider ID NOT DEFINED\n";
			 $errors++;
			 print "This line has a name: $full_name at position $position and rider number: $rider_no\n";
			 print "If any of these three values is EMPTY or erroneous, you need to fix them.\n";
			 print "The stage number is $stage_no.\n";
			 
	}


#	print "The rider ID is $rider_no.\n";
#	print "The position is $position \n";
#	print "The counter is $counter \n";
#	print "The value of array[-1] is $array[-1]\n";
#	print "Getting ready for next line. The value of A is $a\n";

	if ($counter < 1) { 	# one-time run to collect the unique first line of the file
		if ($array[-1] =~ /:/) 
		{
			print "The last string in the line is $array[-1] \n";
			$a = &convert_to_seconds;
			$array[-1] = $a;
			$overall = $a;
			print "The overall time is: $overall \n";
			$counter++;
			$b = &convert_to_date;
			$array[-1] = $b;
			print "A is now $a\n";
		} else {
			push(@array,$a);
			$counter++;
			print "A is now $a\n";
		}
		
	} else {
		if ($array[-1] =~ /:/)
		{
			$a = &convert_to_seconds + $overall;
			$array[-1] = $a;
			$b = &convert_to_date;
			$array[-1] = $b;
			print "A is now $a\n";
		} else {
			push(@array,$a);
			$b = &convert_to_date;
			$array[-1] = $b;
			print "No time on this line so pushing $a and making last element $b\n";
			} 

	}

$time = $array[-1];

# Output for debugging purposes only.

print "This line has a rider name: $full_name and rider number: $rider_no AND a time of $time AND position: $position.\n";
print "The stage number is $stage_no.\n";

# WE NEED RIDER IDs FIRST OFF. THEN WE CAN UPDATE WITH INFO FROM EACH STAGE


	if ($stage_no == 1)
	{
	my $query = "INSERT INTO $race_name(rider_id) values($rider_no)";
	my $sth = $dbh->prepare($query);
	$sth->execute();
	}



	my $query2 = "UPDATE $race_name SET s$stage_no = $position WHERE rider_id = $rider_no";
	my $sth2 = $dbh->prepare($query2);
	$sth2->execute();

	my $query3 = "UPDATE $race_name SET t$stage_no = \'$time\' WHERE rider_id = $rider_no";
	my $sth3 = $dbh->prepare($query3);
	$sth3->execute();



	close STAGES;
	}
					
	$upload_file_no++;

	}	# CLOSE THIS WHILE LOOP and go to the next one


	$dbh->disconnect; # When all while loops are done


# Do all the above unless user input an incorrect value when selecting event

} else {			
	
	print "Sorry... That's not a valid number. Try again\n";
	$dbh->disconnect;	
}

