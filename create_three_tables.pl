#!/usr/bin/perl -w
use DBI;
print "To create the database, I need to know an MySQL administrator\n";
print "name and password. Please enter the admin name here: \n";  
$admin_name = <STDIN>;
chomp ($admin_name);
print "\nNow please provide the password: \n";
$admin_pw = <STDIN>;
chomp ($admin_pw);

print "Great. Give me a sec, I will try using $admin_name and $admin_pw.\n";

my $server = 'localhost';
my $db = 'races';
#my $username =  "\'$admin_name\'";
my $username = $admin_name;
my $password = $admin_pw;

#my $password = "\'$admin_pw\'";

my $dbh = DBI->connect("dbi:mysql:$db:$server", $username, $password);

my $query1 = "CREATE TABLE countries (country_id SMALLINT(4) UNSIGNED NOT NULL AUTO_INCREMENT, 
country CHAR(5) NOT NULL, PRIMARY KEY (country_id) )";

my $sth = $dbh->prepare($query1);

$sth->execute();

my $query2 = "CREATE TABLE teams (team_id SMALLINT(4) UNSIGNED NOT NULL AUTO_INCREMENT, 
team VARCHAR(50) NOT NULL, PRIMARY KEY (team_id) )";

my $sth = $dbh->prepare($query2);

$sth->execute();

my $query3 = "CREATE TABLE riders (rider_id SMALLINT(4) UNSIGNED NOT NULL AUTO_INCREMENT, 
rider_name VARCHAR(40) NOT NULL DEFAULT 'Unknown', country_id SMALLINT(4) UNSIGNED NOT NULL, 
team_id SMALLINT(4) UNSIGNED NOT NULL, PRIMARY KEY (rider_id) )";


my $sth = $dbh->prepare($query3);

$sth->execute();



$dbh->disconnect;
