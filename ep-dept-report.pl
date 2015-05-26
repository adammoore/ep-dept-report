#!/usr/bin/perl -I/eprints/eprints3/perl_lib

use strict;
use warnings;

use EPrints;
use Data::Dumper;
use Text::CSV_PP; #always use a library!

binmode(STDOUT, ':utf8');

my $repositoryid = $ARGV[0];
die "USAGE: report.pl *repositoryid* \n" unless $repositoryid ;

my $ep = EPrints->new();
my $repo = $ep->repository( $repositoryid );
die "Could not create repository object for $repositoryid\n" unless $repositoryid;

my $ds = $repo->dataset('archive');

#first count how many users in each department
my $department_membership = department_membership_search($repo);

#now count how many publications in each department
my $department_counts = department_counts($repo);

output_report($department_membership, $department_counts);


sub output_report
{
	my ($dept_membership, $dept_counts) = @_;

	$csv = Text::CSV_PP->new({binary => 1});

	$csv->combine('Department Name','Number of Staff','Total Items','Items with ID over 2M','Public Docs','Private Docs');
	print($csv->string);

	foreach my $dept (sort keys %{$dept_membership})
	{
		my @line = ();
		push @line, $dept;
		push @line, $dept_membership->{$dept};
		foreach my $k (qw/ total new public private /)
		{
			push @line, $dept_counts->{$dept}->{$k};
		}
		$csv->combine(@line);
		print($csv->string);
	}
}


sub department_membership_search
{
	my ($repo) = @_;

	my $sql = "SELECT `dept`, COUNT(*) FROM `user` GROUP BY `dept`"; #do it this way, then you won't have to do multiple searches

	my $department_membership = {};

        my $sth = $repo->get_database->prepare( $sql );
        $sth->execute;

        while(my @row = $sth->fetchrow_array)
        {
		$department_membership->{$row[0]} = $row[1];
	}
	return $department_mambership;
}


sub department_counts
{
	my ($repo) = @_;

	my $counts = {};

	my $ds = $repo->dataset('archive');
	$ds->search()->map( sub
	{
		my ($repo, $ds, $dataobj, $counts) = @_;

		my $user = $dataobj->get_user;
		my $dept = $user->value('dept'); #or whichever field

		my @docs = $dataobj->get_all_documents;
		my $public = 0;
		my $private = 0;
		foreach my $doc (@docs)
		{
			if ($doc->value('security') eq 'public')
			{
				$public++;
			}
			else
			{
				$private++;
			}
		}

		if ($public)
		{
			$counts->{$dept}->{public}++;
		}
		elsif ($private)
		{
			$counts->{$dept}->{private}++;
		}
		if ($dataobj->get_value("eprintid") >2000000)
		{
			$counts->{$dept}->{new}++;
		}
		$counts->{$dept}->{total}++;

	}, $counts);

	return $counts
}
