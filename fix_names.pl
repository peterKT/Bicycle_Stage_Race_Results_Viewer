#!/usr/bin/perl -w


# Fix all the bad names

# First, get the good names
$counter = 0;

open CHECK_NAME, "<", "/tmp/races/new_names.txt";
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


open EVENT, "</tmp/races/race_name.txt";


	foreach (<EVENT>)
		{
		chomp;
		$event = $_ ; 
		} 
close EVENT;

# Figure out how many files we need to check

 $counter = 1;

 $stages = 0;


while ($counter < 23)
 {
	$filename = "/tmp/races/$event/stage$counter.csv";
	if (-e $filename) {
	  $stages++;
	}	 
	$counter++;
 }

print "The number of files in the folder is $stages\n";

 $count = 1;			# Not to be confused with any other counter



while ( $count <= $stages )

{

open STAGES, "<", "/tmp/races/$event/stage$count.csv";

# Take each name from each line and find the correct name by matching with good_names


%{$real_name} = ();
$found_match = 0;
$problems = 0;
@problem_names = ();

foreach (<STAGES>) 

# Take each rider name (in full) and try to match it with each name in the rider dictionary (new_names.txt)

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
foreach $elem(@problem_names) {
	print "$elem\n";
}

# Set up name-matching tests in event simple match above fails to work 100% of the time (most likely).
# Run while problems are not zero.


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
  	
		print "Checking problem partial name taken from $full_name against $value\n";
		$_ = $value;
		$match = 0;
		foreach $elem(@last_chance) {
			$try_me = substr($elem, 0,3);	
			if (/$try_me/) { 
			
				print "MATCH! $try_me matches on $value\n\n"; 
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
	print "Trying CHECK TWO to fix $problems not fixed by CHECK ONE\n";
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
	print "No problems: Check three says $problems is zero\n";
	}

if ($problems != 0) {
	print "Trying CHECK FOUR for $problems problems\n";
	&check4;
	} else {
	print "No problems: Check four says $problems is zero\n";
	}

if ($problems != 0) {
	print "Trying CHECK FIVE for $problems problems\n";
	&check5;
	} else {
	print "No problems:  Check five says$problems is zero\n";
	}

if ($problems != 0) {
	print "Tried everything and you still have $problems  problems: \n";
	foreach $elem(@fix_me4) {
		print "$elem\n";
	}
}

# END CHECK PROBLEMS


print "\n\n";

# Look at the last hash

while ( ($key, $value) = each %real_name ) {
	print "$key => $value\n";
	}

print "You have $problems problem names.\n";


if ($problems == 0) 
  {

	# OPEN STAGES AND FIX THE BADLY FORMED NAMES



	@ARGV = glob "/tmp/races/$event/stage$count.csv" or die "Could not open file stage$count.csv";
	$^I = ".bak";

	while (<>) 
	{
		@array1 = ();
#		chomp;
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
	$count = ($stages + 1);	
	print "Sorry, you are stuck here until you fix $problems problems\n";
	print "The value of count is $count\n";
  }

}	# CLOSE while stages less than total (go to next report)

