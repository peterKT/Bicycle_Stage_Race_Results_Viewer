#!/usr/bin/perl -w
use DBI;
use File::Path

#UPLOAD DATA
print "\n\tTo identify the event you want to upload stage result info for,\n\tI need to access the database\n";
print "\tusing an account with write permissions. Please enter the user name here: \n";  
$admin_name = <STDIN>;
chomp ($admin_name);
print "\n\tNow please provide the password: \n";
$admin_pw = <STDIN>;
chomp ($admin_pw);

print "\tGreat. Give me a sec, I will try using $admin_name and $admin_pw.\n";

my $server = 'localhost';
my $db = 'races';
my $username = $admin_name;
my $password = $admin_pw;

my $dbh = DBI->connect("dbi:mysql:$db:$server", $username, $password);

# Get available races

my $query0 = "SELECT table_name FROM information_schema.tables WHERE table_schema='races' AND table_name != 'riders' AND table_name != 'countries' AND table_name != 'teams'";
my $sth = $dbh->prepare($query0);
$sth->execute();

$counter = 0;
print "\n\n";

while (my $row = $sth->fetchrow_arrayref) 
	{	
		$counter++;
		$pick = @$row[0];
#		print "The key is $counter and the value is $pick\n";
		$selection{$counter} = $pick;
		print "\tChoose $counter for this race: $selection{$counter}\n";

	}
$choice = <STDIN>;
chomp ($choice);

if ( ($choice > 0) && ($choice <= $counter) ) {

	print "\tGreat! Everything is ready for $selection{$choice}\n\n";

	$race_name = $selection{$choice};

	} else {			
	
	die "$choice is not a valid number\n";
	$dbh->disconnect;	
}


# If results folder got deleted, recreate it and tell user to place files in it, then 
# fix names for files not yet uploaded. Otherwise, fix names for files not yet uploaded.

$folder_name = "/tmp/races/$race_name";

if (-e $folder_name) {
	print "The folder exists. If you have not already done so, please make\n";
	print "sure the folder contains a complete set of your stage results files,\n";
	print "including newly added ones.\n";
	} else {
	print "The folder does not exist so a new one is created.\n";
	print "Please copy your stage results files (all of them) into /tmp/races/$race_name.\n";
	print "and re-run me.\n";


	$newdir = "/tmp/races/$race_name";
	mkpath ($newdir);
	chmod (0777, '/tmp/races');
	chmod (0777, $newdir);
	die "A restart of your computer may have eliminated the /tmp/races directory so we\nneed to recreate it\n";
}	# CLOSE else (if folder did not exist)


$file_name = "/tmp/races/new_correct_names.txt";

if (-e $file_name) {	# Go ahead and fix the names in not-yet-processed files

	print "Good to go forward.\n";

	} else {	# OPEN if the new correct names file does not exist

	# Create a new copy of the definitive rider name file using stage1.csv 

	open GET_NAMES, "<", "/tmp/races/$race_name/stage1.csv";
	open WRITE_NAMES, ">", "/tmp/races/correct_names.txt";

	foreach (<GET_NAMES>) # Build an array @array3 consisting of rider names 
	{
		chomp;
		@array2 = split /\t/, $_ ; # Capture one line of text from the file 
#		$delete_me = shift(@array2); # Get rid of the position number
		shift(@array2); # Get rid of the position number
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
	print WRITE_NAMES @array3;

	close GET_NAMES;
	close WRITE_NAMES;

	
	open CHANGE_NAMES, ">", "/tmp/races/new_correct_names.txt";
	open WRITE_NAMES, "<", "/tmp/races/correct_names.txt";

# QUICK, GET RID OF THAT UNWANTED SPACE AT LINE END

	foreach (<WRITE_NAMES>)
	{
	  s/ \n/\n/;
	  print CHANGE_NAMES $_; 
	}	

	close WRITE_NAMES;
	close CHANGE_NAMES;

}	# CLOSE if the new correct names file did not exist



# Figure out if any stage results have been entered already and if so how many

my $query01 = "SELECT COUNT(*) AS column_count FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='$race_name'";
my $sth01 = $dbh->prepare($query01);
$sth01->execute();

while (my $row = $sth01->fetchrow_arrayref) {
		
		$table_columns = @$row[0];

	if ($table_columns == 2) {
		print "You have not entered an results yet.\n";
		$results_input = 0;
#		die "Please try again\n";
		} else {

		$results_input = ($table_columns - 2) / 2;
		print "You have already input results for $results_input stages\n";
		}		
}

# Fix names in all results files not yet input, i.e. where the stage number is > $results_input
# Don't forget to put them back the way they were after fixing them.

$counter = 0;

open CHECK_NAME, "<", "/tmp/races/new_correct_names.txt";
foreach (<CHECK_NAME>) 

{
	chomp;
	$good_name{$counter} = $_;	
	$counter++;
}

$fourth = $good_name{3};
$total_names = $counter;

print "The dictionary has $total_names names in a hash starting at key value zero.\n";
print "For example, the fourth hash value is $fourth\n";
close CHECK_NAME;


 $counter = 1;

 $num_files = 0;


while ($counter < 23)
 {
	$filename = "/tmp/races/$race_name/stage$counter.csv";
	if (-e $filename) {
	  $num_files++;
	}	 
	$counter++;
 }

print "The number of files in the folder is $num_files\n";

$folder_name = "/tmp/races/$race_name";

# If no files in folder stop here

if ($num_files == 0) {
	print "You need to put all your stageX.csv files into the results folder.\n";
	die "Please try again\n";
}


# Now, in the event the user added just one or two new results files after
# processing a previous batch, focus on reports for stages
# not already entered in the database. This may be one or more but we need
# to calculate the stage number appended to the file name. $num_files gives only
# the number of files now available and may include previously processed
# reports. We don't want to bother with those again, but they should be present in the folder.


$start_at = $results_input + 1;

# If no new files in folder stop here

$check_file_name = "/tmp/races/$race_name/stage$start_at.csv";

if (-e $check_file_name) {
	print "You have at least one new results file to add starting at stage $start_at. Going ahead.\n";
	} else {
	die "You need to add results for a new stage.\n";
	}

$count = $start_at;


 # BEGIN processing files not yet dealt with


while ( $count <= $num_files )
{

	$filename = "/tmp/races/$race_name/stage$count.csv";
	if (-e $filename) {

		open STAGES, "<", "/tmp/races/$race_name/stage$count.csv";


		# Take each name from each line and find the correct name by matching with good_names


		%{$real_name} = ();
		$found_match = 0;
		$problems = 0;
		@problem_names = ();
		$line_no = 0;

		foreach (<STAGES>) 



		# Take each rider name (in full) and try to match it with each name in the rider dictionary (new_names.txt)

		{
			$line_no++;	# Keep track of line number for error correction if needed
#			print "I am at line number $line_no\n";

			@array1 = ();
			chomp;
			@array1 = split /\t/, $_; # Capture line of text from the file 

			# STOP if no nationality. Throws off name definition. Fix erroneous line first.


				if ($_ =~ /\(/ ) {
					print "Found parens, OK to go ahead.\n";
				} else {
				die "Found a line $line_no with no nationality in results for stage $count. You need to fix and re-run me.\n";
				}


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

			$a = $name_elements - 2;
			$b = $name_elements - 1;

			$full_name = join " ", @array2;	# Put the name back together for later use

			print "I got a name $full_name composed of " . $array2[0] . " and " . $array2[1] . "\n";
			print "(at least) that has $name_elements elements\n";

			# This matches exact duplicate names. 

			$found_match = 0;


  			for $value ( values %good_name )
  			{
				print "Checking $full_name against $value\n";
				$_ = $value;


	  			if (/$full_name/)
          			{ 
					print "MATCH! $full_name matches on $value\n\n"; 

					print "That means the reported name $full_name is the same as $value\n";		
					$found_match++;
					$real_name{$full_name} = $value;
					last;
	  			} 
	
   			}	# CLOSE FOR $VALUE



			# Done looking for match of one line from report
			# Before moving on, make a note if no match was found

			if ($found_match == 0) {
				print "Problem name is $full_name\n";
				$problems++;
				print "The number of problem names is now $problems\n";
				push @problem_names, $full_name;
			}	


			print "Closing for each line of the file\n";

		}	# CLOSE  FOREACH LINE OF STAGES FILE

	
		close STAGES;


		# Go through hash for stage result name parts and look for matches in name strings stored in the good_names hash

		print "The total problems in stage $count was $problems:\n";

		$debug1 = $count;
		$debug2 = $problems;

		foreach $elem(@problem_names) {
			print "$elem\n";
		}

		# Set up name-matching tests in event simple match above fails to work 100% of the time (most likely).
		# Run while problems are not zero.

# TEMP suspend proper tab spaces

# This name is mispelled or mutilated in so many different ways that it needs a special check: Jhonatan Manuel Narvaez Prado



sub check1 {
	@last_chance = ();
	@fix_me1 = ();

	# Try matching the first two elements of the name individually
	
	foreach $elem(@problem_names) {
		$found_match = 0;
		$full_name = $elem;
		@last_chance = split /\s+/, $elem;
		$name1 = shift(@last_chance);
		$name2 = shift(@last_chance);

		for $value ( values %good_name )
  		{
			print "Checking problem name $full_name against $value using $name1 and $name2 separately.\n";
			$_ = $value;

			if (/$name1/) {
				print "MATCH! $name1 matches on $value\n\n"; 

				if (/$name2/) {
					print "ANOTHER MATCH. By George we've done it. $name2 is also here.\n";
					print "So we will be using the dictionary name $value for this guy\n";
					$real_name{$full_name} = $value;
					$problems = ($problems - 1);
					print "ONE problems are now $problems in number\n";
					$found_match++;
					last; 	# Stop matching
					} else {
					print "False Alarm $name2 not here.\n";
					
				}



			}	# CLOSE if name1
   		}	# CLOSE FOR Value

	if ($found_match == 0)
		{
			print "Sorry, no matches on both $name1 and $name2. Dumping $full_name into fix_me1\n";
			push(@fix_me1, $full_name);			
		} else {
			print "Match was made\n";
		}

	}	# CLOSE foreach elem of the problem_names

}	# End routine definition







sub check1a {
	@last_chance = ();
	@fix_me1 = ();

	# Try matching the first two elements of the name individually; special case for two hard to correct names
	
	foreach $elem(@problem_names) {
		$found_match = 0;
		$full_name = $elem;
		@last_chance = split /\s+/, $elem;
		$name1 = shift(@last_chance);
		$name2 = shift(@last_chance);

		for $value ( values %good_name )
  		{
			print "Checking problem name $full_name against $value using $name1 and $name2 separately.\n";
			$_ = $value;

			if (/$name1/) {
				print "MATCH! $name1 matches on $value\n\n"; 

				if (/$name2/) {
					print "ANOTHER MATCH. By George we've done it. $name2 is also here.\n";
					print "So we will be using the dictionary name $value for this guy\n";
					$real_name{$full_name} = $value;
					$problems = ($problems - 1);
					print "ONE problems are now $problems in number\n";
					$found_match++;
					last; 	# Stop matching
					} else {
					print "False Alarm $name2 not here.\n";
					
				}



			}	# CLOSE if name1
   		}	# CLOSE FOR Value

		# IF Jonnathan Narvaez ever shows up

		if ($name1 == 'Jonnathan' && $name2 == 'Narvaez') {
			$name1 = 'Jhonnatan';
			for $value ( values %good_name )
  			{
				print "Checking problem name $full_name against $value using $name1 and $name2 separately.\n";
				$_ = $value;

				if (/$name1/) {
					print "MATCH! $name1 matches on $value\n\n"; 

					if (/$name2/) {
						print "ANOTHER MATCH. By George we've done it. $name2 is also here.\n";
						print "So we will be using the dictionary name $value for this guy\n";
						$real_name{$full_name} = $value;
						$problems = ($problems - 1);
						print "ONE problems are now $problems in number\n";
						$found_match++;
						last; 	# Stop matching
						} else {
						print "False Alarm $name2 not here.\n";
					
					}



				}	# CLOSE if name1
   			}	# CLOSE FOR Value
		}	# CLOSE special case search on Jonnathan Narvaez



	if ($found_match == 0)
		{
			print "Sorry, no matches on both $name1 and $name2. Dumping $full_name into fix_me1\n";
			push(@fix_me1, $full_name);			
		} else {
			print "Match was made\n";
		}

	}	# CLOSE foreach elem of the problem_names

}	# End routine definition




sub check1b {
	@last_chance = ();
	@fix_me1 = ();

	# Try matching the first two elements of the name individually; special case for two hard to correct names
	
	foreach $elem(@problem_names) {
		$found_match = 0;
		$full_name = $elem;
		@last_chance = split /\s+/, $elem;
		$name1 = shift(@last_chance);
		$name2 = shift(@last_chance);

		for $value ( values %good_name )
  		{
			print "Checking problem name $full_name against $value using $name1 and $name2 separately.\n";
			$_ = $value;

			if (/$name1/) {
				print "MATCH! $name1 matches on $value\n\n"; 

				if (/$name2/) {
					print "ANOTHER MATCH. By George we've done it. $name2 is also here.\n";
					print "So we will be using the dictionary name $value for this guy\n";
					$real_name{$full_name} = $value;
					$problems = ($problems - 1);
					print "ONE problems are now $problems in number\n";
					$found_match++;
					last; 	# Stop matching
					} else {
					print "False Alarm $name2 not here.\n";
					
				}



			}	# CLOSE if name1
   		}	# CLOSE FOR Value

		# IF Rüdiger Selig ever shows up

		if ($name1 == 'Rüdiger' && $name2 == 'Selig') {
			$name1 = 'Rudiger';
			for $value ( values %good_name )
  			{
				print "Checking problem name $full_name against $value using $name1 and $name2 separately.\n";
				$_ = $value;

				if (/$name1/) {
					print "MATCH! $name1 matches on $value\n\n"; 

					if (/$name2/) {
						print "ANOTHER MATCH. By George we've done it. $name2 is also here.\n";
						print "So we will be using the dictionary name $value for this guy\n";
						$real_name{$full_name} = $value;
						$problems = ($problems - 1);
						print "ONE problems are now $problems in number\n";
						$found_match++;
						last; 	# Stop matching
						} else {
						print "False Alarm $name2 not here.\n";
					
					}



				}	# CLOSE if name1
   			}	# CLOSE FOR Value
		}	# CLOSE special case search on Rüdiger Selig



	if ($found_match == 0)
		{
			print "Sorry, no matches on both $name1 and $name2. Dumping $full_name into fix_me1\n";
			push(@fix_me1, $full_name);			
		} else {
			print "Match was made\n";
		}

	}	# CLOSE foreach elem of the problem_names

}	# End routine definition




sub check2 {

# Go back and try to match the leftover names by using just the first three letters of
# each name element. Still must get two matches. Solves the Jonny not matching Jon type problem.
@last_chance = ();
@fix_me2 = ();

foreach $elem(@fix_me1) {
	$full_name = $elem;
	@last_chance = split /\s+/, $elem;
	$found_match = 0;
  	for $value ( values %good_name ) {
  	
		print "\n\nChecking problem partial name taken from $full_name against $value\n";
		$_ = $value;
		$match = 0;
		foreach $elem(@last_chance) {
			$try_me = substr($elem, 0,3);	
			if (/$try_me/) { 
			
				print "\nMATCH! $try_me matches on $value\n\n"; 
				print "The value of matches for this line is $match plus one\n";
				$match++;
				} else {
				print "Problem element $try_me did not match anything\n";
			}
		}	# CLOSE check each partial segement of the name in last_chance		



		if ($match > 1) {	# Must be more than one, otherwise Joe Smi would match on Joe Bro
			print "Because at least two name elements match, we can conclude the real name is $value\n";
			# We need the whole name now

			print "That means the reported name $full_name is the same as $value\n";		
			$found_match++;     
			$real_name{$full_name} = $value;
			$problems = ($problems - 1);
			print "There are now $problems problem names.\n";
			last;
			} else {
			print "Problem name $full_name still did not match anything\n";

		}

	}	# CLOSE check against good_name list
	if ($found_match == 0) {
		push(@fix_me2, $full_name);	# New problem_names array. Won't include matched.
		print "Dumping $full_name into fix_me2. No match found in Check Two.\n";
	}	# After looping through the entire good_name list, if no match found, dump into fix_me2




}	# End foreach line of the problem names array now called fix_me1

print "Check 2 says there are now $problems problems\n";

}	# End routine definition



# FINAL CHECK 3  Use first name and first letter of last name combined with some letters at the end.

sub check3 {

@last_chance = ();
@fix_me3 = ();

$match = 0;

foreach $elem(@fix_me2) {
	$full_name = $elem;
	@last_chance = split /\s+/, $elem;
	$first_name = shift(@last_chance);
	$found_match = 0;



for $value ( values %good_name )
{
	print "Checking $first_name against $value\n";
	$_ = $value;
	$match = 0;

	if (/$first_name/)
	  { 
		print "MATCH! $first_name matches on $value\n\n"; 
		print "The value of matches for this line is $match plus one\n";

		$match++;



		foreach $elem(@last_chance) 
		  {
			
			# Take a peek at the first letter of this name element and last two letters.
			# Seems risky but only comes into play when one name element matches but the others do not
			# which can be caused by diacritics going missing etc. in addition to simply Joe Smith 
			# being allowed to match on Joe Sharp
			# PROBLEM!
			# That means the reported name Adam De Vos is the same as Dennis Van Winden
			# because De matches and V matches. Thus the need for an additional two-letter match.

			# This solution (matching again on the last two letters of the name if the first letter finds
			# a match seems to work in almost all cases. Problem diacritics that can often get dropped,
			# thus failing to match, are most frequently found in the middle of the names.

			$letter = substr($elem, 0,1);
			print "Peeking with $letter\n";
			if (/$letter/) {
				$length = length($elem);
				$letters = substr($elem, $length - 2,2);
				print "Peeking with $letters\n";
				if (/$letters/) {

					print "MATCH! $full_name matches on $value BECAUSE $first_name\n";
					print "AND $letter AND $letters matches\n"; 
					print "The value of matches for this line is $match plus one\n\n";

					$match++;
					last;
				}
			}
		}	# Close foreach @last_chance
	   }	# Close if first_name  

	if ($match > 1) {				# Must be more than one, otherwise Joe Smith would match on Joe Brown
		print "Because at least two name elements match, we can conclude the real name is $value\n";
		# We need the whole name now

		print "That means the reported name $full_name is the same as $value\n";		
		$found_match++;
		$real_name{$full_name} = $value;
		$problems = ($problems - 1);
		last;
	 	} else {
		print "Problem name $full_name still did not match anything\n";

		}
	

}	# Close for values
if ($found_match == 0) {
	push(@fix_me3, $full_name);	# New problem_names array. Won't include those that matched.
	print "Adding $full_name to new problems array fix_me3\n";
}

}	# Close foreach of the names in @problem_names



}	# End routine definition


# FINAL CHECK 4  Use first three letters of first name and first letter of last name combined with some letters at the end.

sub check4 {

@last_chance = ();
@fix_me4 = ();

$match = 0;

foreach $elem(@fix_me3) {
	$full_name = $elem;
	@last_chance = split /\s+/, $elem;
	$first_name = shift(@last_chance);
	$first_name = substr($first_name, 0,3);
	$found_match = 0;



for $value ( values %good_name )
{
	print "Checking against $value\n";
	$_ = $value;
	$match = 0;

	if (/$first_name/)
	  { 
		print "MATCH! $first_name matches on $value\n\n"; 
		print "The value of matches for this line is $match plus one\n";

		$match++;



		foreach $elem(@last_chance) 
		  {
			
			# Take a peek at the first letter of next name element and last two letters.
			# Seems risky but only comes into play when one name element matches but the others do not
			# which can be caused by diacritics going missing etc. in addition to simply Joe Smith 
			# being allowed to match on Joe Sharp
			# PROBLEM!
			# That means the reported name Adam De Vos is the same as Dennis Van Winden
			# because De matches and V matches. Thus the need for an additional two-letter match.

			# This solution (matching again on the last two letters of the name if the first letter finds
			# a match) seems to work in almost all cases. Problem diacritics that can often get dropped,
			# thus failing to match, are most frequently found in the middle of the names.

			$letter = substr($elem, 0,1);
			print "Peeking with $letter\n";
			if (/$letter/) {
				$length = length($elem);
				$letters = substr($elem, $length - 2,2);
				print "Peeking with $letters\n";
				if (/$letters/) {

					print "MATCH! $full_name matches on $value BECAUSE\n";
					print "$first_name AND $letter AND $letters matches\n"; 
					print "The value of matches for this line is $match plus one\n\n";

					$match++;
					last;
				}
			}
		}	# Close foreach @last_chance
	   }	# Close if first_name  

	if ($match > 1) {				# Must be more than one, otherwise Joe Smith would match on Joe Brown
		print "Because at least two name elements match, we can conclude the real name is $value\n";
		# We need the whole name now

		print "That means the reported name $full_name is the same as $value\n";		
		$found_match++;
		$real_name{$full_name} = $value;
		$problems = ($problems - 1);
		last;
	 	} else {
		print "Problem name $full_name still did not match anything\n";

		}
	

}	# Close for values
if ($found_match == 0) {
	push(@fix_me4, $full_name);	# New problem_names array. Won't include those that matched.
	print "Adding $full_name to new problems array fix_me4\n";
}

}	# Close foreach of the names in @fix_me2



}	# End routine definition


# FINAL CHECK 5  One last try. If the first three letters of first name plus first letter of
# each additional name elements matches. Only being used as last resort
# when problem names are few. Need to match name like Pier-Andre Cote with Pier-André Côté

sub check5 {

@last_chance = ();
@fix_me5 = ();

$match = 0;

foreach $elem(@fix_me4) {
	$full_name = $elem;
	@last_chance = split /\s+/, $elem;
	$first_name = shift(@last_chance);
	$second_name = shift(@last_chance);
	$first_name = substr($first_name, 0,3);
	$second_name = substr($second_name, 0,1);
		if (@last_chance != 0) {
		$third_name = shift(@last_chance);
		$third_name = substr($third_name, 0,1);
		}
	$found_match = 0;
	print "Check 5 says I am now going to try to match $full_name using only $first_name and $second_name.\n";
	if ($third_name) {
	print "I'll throw $third_name in for good measure.\n";
	}


  for $value ( values %good_name )
  {
	print "Checking against $value\n";
	$_ = $value;
	$match = 0;

	if (/$first_name/)
	{ 
		print "MATCH! $first_name matches on $value\n\n"; 
		print "The value of matches for this line is $match plus one\n";

		$match++;

		print "Peeking with $second_name\n";
		if (/$second_name/) {
			print "Another MATCH! $second_name found in $value\n";
			$match++;
			}
	}

	if ($match == 2) {
		print "We have $match matches. If a third name element is involved we will try that too.\n";
	} 	

	if ($third_name) {
		if (/$third_name/) {
			print "We got a match on the third name element: $third_name!\n";
			$match++;		
		}
	}

	print "Done trying. We got $match matches\n";



	if ($match > 1) {		# Must be more than one, otherwise Joe Smith would match on Joe Brown
		print "Because at least two name elements match, we can conclude the real name is $value\n";
		# We need the whole name now

		print "That means the reported name $full_name is the same as $value\n";		
		$found_match++;
		$real_name{$full_name} = $value;
		$problems = ($problems - 1);
		last;
	} else {
		print "Problem name $full_name still did not match anything\n";
	}
	

}	# Close for values
	if ($found_match == 0) {
		push(@fix_me5, $full_name);	# New problem_names array. Won't include those that matched.
		print "Adding $full_name to new problems array fix_me5\n";
		}

}	# Close foreach of the names in @fix_me4



}	# End routine definition




if ($problems != 0) {
	print "Trying CHECK ONE for $problems problems\n";
	&check1;
	} else {
	print "First check says No problems with this stage.\n";
	}

if ($problems != 0) {
	print "Trying CHECK ONE-A for $problems problems\n";
	&check1a;
	} else {
	print "First check says No problems with this stage.\n";
	}

if ($problems != 0) {
	print "Trying CHECK ONE-B for $problems problems\n";
	&check1b;
	} else {
	print "First check says No problems with this stage.\n";
	}

if ($problems != 0) {
	print "Trying CHECK TWO to fix $problems problem(s) not fixed by CHECK ONE\n";
	&check2;
	} else {
	print "Check two says All problems fixed!\n";
	}

if ($problems != 0) {
	print "Trying CHECK THREE for $problems problems\n";
	print "The problem names are stored in fix_me2 THUS: \n";
	foreach $elem(@fix_me2) {
		print "CHECK THREE problem name: $elem\n";
		}
	&check3;
	} else {
	print "No problems: Check three says problems is zero\n";
	}

if ($problems != 0) {
	print "Trying CHECK FOUR for $problems problems\n";
	&check4;
	} else {
	print "No problems: Check four says problems is zero\n";
	}

if ($problems != 0) {
	print "Trying CHECK FIVE for $problems problems\n";
	&check5;
	} else {
	print "No problems:  Check five says problems is zero\n";
	}




if ($problems != 0) {
	print "Tried everything and you still have $problems problem(s): \n";
	foreach $elem(@fix_me5) {
		print "$elem\n";
		}
	}


# END CHECK PROBLEMS -- Return to proper tab spaces


		print "\n\n";

		# Look at the last hash

		while ( ($key, $value) = each %real_name ) {
			print "$key => $value\n";
		}

		print "You have $problems problem names.\n";


		if ($problems == 0) 
  		{

			# OPEN STAGES AND FIX THE BADLY FORMED NAMES



			@ARGV = glob "/tmp/races/$race_name/stage$count.csv" or die "Could not open file stage$count.csv";
			$^I = ".bak";

			while (<>) 
			{
				@array1 = ();

				@array1 = split /\t/, $_; # Capture line of text from the file 
				@array2 = ();
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

				$full_name = join " ", @array2;	# Put the name back together

				s/	/ /g;

				s/$full_name/$real_name{$full_name}/;

				print;
		#		print "\nI just switched full name $full_name with $real_name{$full_name} the real name.\n";
			}	
			$count++;
  		} else {
		$error_file = $count;
#		$count = ($num_files + 1);	
		print "Sorry, you are stuck here until you fix $problems problem(s) noted below in stage $error_file\n";

			foreach $elem(@fix_me5) {
				print "$elem\n";
			}
		print "\n\n";
		die "The value of count is $count which means you got stopped at a problem name in the stage $error_file file.\n";
  		}
	}	# CLOSE if the file exists

}	# CLOSE while count is less than num_files)


print "Ready to start data upload.\n";

$count = $start_at;
 $new_stages = 0;

# Name matching and fixing required converting tabs to spaces. We now convert back to tabs.
# Space separated version consigned to .bak file.

while ( $count <= $num_files )
 {
	$filename = "/tmp/races/$race_name/stage$count.csv";
	if (-e $filename) {
	@ARGV = glob "/tmp/races/$race_name/stage$count.csv" or die "Could not open file stage$count.csv";
	$^I = ".bak";

	while (<>) 
	{
		s/ /	/g;
		print;
	}

	  $new_stages++;
	}	 
	$count++;
 }

print "The number of new stages being added today is $new_stages\n";
print "We start adding data with the file for stage $start_at\n";



# Add appropriate number of fields to event table

#my $query0 = "CREATE TABLE $race_name (rider_id SMALLINT(4) UNSIGNED NOT NULL, total_stages SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0', s1 SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0', t1 TIME, PRIMARY KEY (rider_id) )";


$counter3 = $start_at;
$counter4 = 1;

while ($counter4 <= $new_stages) {

  my $query2 = "ALTER TABLE $race_name ADD COLUMN s$counter3 SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0', ADD COLUMN t$counter3 TIME";

  my $sth = $dbh->prepare($query2);
  $sth->execute();
  $counter3++;
  $counter4++;

}


my $query02 = "SELECT rider_id,rider_name from riders INTO OUTFILE '/tmp/races/riders2.txt'";

my $sth02 = $dbh->prepare($query02);

$sth02->execute();

sub obtain_rider_IDs {

	open RIDERS, "</tmp/races/riders2.txt";


	# IF YOU SEE ERRORS, check this file. The name strings must match the names
	# imported with the daily results. They use the same formula to create string matches,
	# so they should be equal, but stray odd characters or spaces will mess things up.

	foreach (<RIDERS>){
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

}	# End routine definition


sub convert_to_seconds {
	$time = $array[-1];
	@time2 = split /:/, $time;
	$hour = $time2[0];
	$min = $time2[1];
	$sec = $time2[2];
#	$total_seconds = (3600 * $hour) + (60 * $min) + $sec;
	(3600 * $hour) + (60 * $min) + $sec;
}

sub convert_to_date {
	$time = $a;
	$hour = int($time / 3600);
	$time = $time - ($hour * 3600);
	$min = int($time / 60);
	$sec = $time - ($min * 60);
#	$date = join ":", $hour, $min, $sec;
	join ":", $hour, $min, $sec
}

&obtain_rider_IDs;

$counter = 0;
$counter2 = 1;
$upload_file_no = $start_at;


# This refers to the stage results file you are opening. Only files for
# stages that have not yet been entered will be considered. Therefore
# you can delete all results files, re-add them with some new ones to boot,
# and only the new ones will be worked on. Accommodates day-by-day updating.

# foreach (<>) will look at these files line by line

while ( $counter2 <= $new_stages )

{
	open STAGES, "</tmp/races/$race_name/stage" . $upload_file_no . ".csv";

	$stage_no = $upload_file_no;
	$counter = 0;
	$line_no = 0;

	foreach (<STAGES>) 
	{
		$line_no++;
		# Take each rider name (in full) and try to match it with each name in the rider dictionary (new_correct_names.txt)

		@array = ();
		chomp;
		@array = split /\t/, $_; # Capture line of text from the file 

		@array2 = ();
		$elements = 0;
		$position = shift(@array); # store the position number
		foreach $elem(@array) {
	
			if ( $elem =~ /^\(/ ) {
				$nat = $elem;
				last;	# Stop right here at the nationality field.
	  			} else {
				push(@array2, "$elem");
				$elements++;
			}
		}
		
		# STOP if no nationality. Throws off name definition. Fix erroneous line first.
		if (not defined ($nat) ) {
				
			print "\n\nRider nationality NOT DEFINED on line $line_no.\n";
			print "The stage number is $stage_no.\n";
			die "Upload failed. Note clue above.\n";
		}


		# Got name. 

		# Number of elements in the name

		#	$name_elements = $elements;

		$full_name = join " ", @array2;	# Put the name back together for later use

		$rider_no = $rider_id{$full_name};

# Need to insert MYSQL directive to drop the relevant columns

		if (not defined ($rider_no) ) {
				
			print "\n\nRider ID NOT DEFINED on line $line_no.\n";
			print "This line has a name: $full_name, country is $nat, at position $position and rider number: $rider_no\n";
			print "If any of these three values is EMPTY or erroneous, you need to fix the cause.\n";
			print "Then delete the incomplete columns in the races database (including this stage and those after)\n";
			print "and re-rerun me.\n";
			print "The stage number is $stage_no.\n";
			die "Upload failed. Note clue above; the error should be on a nearby line.\n";
		}



		if ($counter < 1) { 	# one-time run to collect the unique first line of the file
			if ($array[-1] =~ /:/) {
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
			if ($array[-1] =~ /:/){
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

		}	# CLOSE if counter < 1

		$time = $array[-1];

		# Output for debugging purposes only.

		print "This line has a rider name: $full_name and rider number: $rider_no AND a time of $time AND position: $position.\n";
		print "The stage number is $stage_no.\n";

		# WE NEED RIDER IDs FIRST OFF. THEN WE CAN UPDATE WITH INFO FROM EACH STAGE


		if ($stage_no == 1){
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
	}	# CLOSE foreach STAGES
					
	$counter2++;
	$upload_file_no++;

}	# CLOSE THIS WHILE $counter2 <= $new_stages LOOP and go to the next one if needed


$dbh->disconnect; # When all while loops are done

unlink ("/tmp/races/riders2.txt");

# Debugging junk

print "Counter2 is $counter2 and stage_no is $stage_no and new stages is $new_stages\n";
print "Start_at is $start_at and upload_file_no is $upload_file_no\n";
print "The dictionary has $total_names total names.\n";
print "The value of count (the stage number) on line 346 is $debug1 \nand the value of problems is $debug2 but that might just be the last time through.\nLooking at it again problems is $problems.\n";
