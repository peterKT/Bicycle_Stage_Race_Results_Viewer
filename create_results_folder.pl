#!/usr/bin/perl
use File::Path

print "Please enter the name of the race. I will create a new directory\n";
print "in your /tmp folder called \"races\" and it will contain a folder with\n";
print "this name. We need this directory to store "; 
print "files for this particular race.\n";

$race_name = <STDIN>;
chomp ($race_name);

print "Great. The directory where we will be storing files is $race_name\n";

$newdir = "/tmp/races/$race_name";
mkpath ($newdir);
chmod(0777, $newdir);

#Store the name of the directory so it can be found later

open RACE_NAME, ">", "/tmp/races/race_name.txt";

print RACE_NAME "$race_name";

close RACE_NAME;



