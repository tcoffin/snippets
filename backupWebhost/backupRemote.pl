#!/usr/bin/perl
# Created by Tyler Coffin
# License: Creative Commons - Attribution Non-Commercial Share Alike (i.e. enjoy it, use it, extend it but don't profit from it. Oh, and give me some credit so I can google my name and feel good about it)
# Warranty: none. There is a infinitesimally low probability that this code will the result in the death of extremely cute kittens, and in that unlikely event; I am not responsible.

# I hacked this together to backup some websites I have hosted. It only does full backups and in the event of a disaster, provides absolutely no assistance with that recovery (hey, but atleast you have your files!)
# Throw this script in crontab to have the backup happen regularly.

my $sitesconf = '';
my $backupdir = '';

$sitesconf = $ARGV[0];
$backupdir = $ARGV[1];

if ( length ( $sitesconf ) == 0 || length ( $backupdir ) == 0 )
{
	die "usage: backupRemote.pl <path to sites.conf> <local backup path>\n";
}

open ( SITES, $sitesconf ) || die "Unable to open $sitesconf\n";

my $tmpdir = "$backupdir/.tmp" . int(rand(1000));

while ( <SITES> )
{
	chomp;
	( my $host, my $path, my $dbhost, my $dbname, my $dbuser, my $dbpass ) = split ( "," );
	my $datestamp = sprintf "%04d-%02d-%02d-%02d:%02d:%02d", ((localtime)[5]%100+2000, (localtime)[4]+1, (localtime)[3], (localtime)[2], (localtime)[1], (localtime)[0]);

	# rsync -az $host:$path $backupdir/.tmp$RANDOM/
	print "rsync'ing $host:$path\n";
	`rsync -az $host:$path $tmpdir`;
	if ( $? != 0 )
	{
		die "error executing rsync -az $host:$path $tmpdir";
	}

	$archive = "$backupdir/$datestamp" . '.tar.gz';
	# tar -czf `date +%F-%T`.tar.gz $backupdir/.tmp$RANDOM
	`tar --remove-files -czf $archive $tmpdir/*`;

	if ( $? != 0 )
	{
		die "error tar'ing $tmpdir";
	}

	# ssh -C $host 'mysqldump -h $dbhost -u $dbuser -p$dbpass --databases $dbname' | gzip > `date +%F-%T`.sql.gz
	print "dumping database $dbname\n";
	`ssh -C $host 'mysqldump -h $dbhost -u $dbuser -p$dbpass --databases $dbname' | gzip > $backupdir/$datestamp.sql.gz`;

	if ( $? != 0 )
	{
		die "error dumping database $dbname";
	}

}
`rm -rf $tmpdir`;
close SITES;
print "Done\n";
