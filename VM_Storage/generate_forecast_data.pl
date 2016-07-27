#!/usr/bin/perl
#June 30th, 2016
#Mai (Edison) Hua - huamai@berkeley.edu
#Changes:
#1. Adding new features: (every comment fields are case insensitive)
#	A. SLA LSI with comments of ‘LSI’ and revenue of 300
#	B. SLA Cluster Master + DTN with comments of 'cluster master+DTN' and revenue of 300
#	C. VM Medium SLA with comments of 'vm medium SLA' and revenue of 200
#	D. VM Large SLA with comments of 'vm large SLA' and revenue of 225
#	E. VM Small with comments of 'vm small' and revenue of 25
#	F. VM Medium with comments of 'vm medium' and revenue of 50
#	G. VM Large with comments of 'vm large' and revenue of 75
#2. Changes Node_Table, Category_Table indent of category column from -20 to -30 to leave enough space for 'cluster master + DTN'

my %categs;
my %nodedata;
my %nodecatg;

my %customer;
my %project;

my %nodecust;
my %nodeproj;

my %coordtls;


# Set debug to 1 when you want debug information, else keep it 0.
my $debug = 1;


sub print_node_table {
    printf "\n\n%-30s , %-6s , %-5s , %11s\n", "Node Name", "Rate",
        "Count", "Revenue";

    my $nodes_revenue = 0.0;
    my $nodes_count = 0;

    foreach $nodename (sort keys %nodedata)
    {
        $nodes_revenue += $nodedata{$nodename}{'Revenue'};
        $nodes_count += $nodedata{$nodename}{'Qty'};

        printf "%-30s , %6.1f , %5d , %10.1f\n" , $nodename,
            $nodedata{$nodename}{'Revenue'} / $nodedata{$nodename}{'Qty'},
            $nodedata{$nodename}{'Qty'}, $nodedata{$nodename}{'Revenue'};
    }

    print '-' x 50 . "\n";
    printf "%-30s , %6s , %5d , %10.1f\n" , "Total Count & Revenue", "", $nodes_count, $nodes_revenue;
}

sub print_category_table {
    printf "%-30s , %-6s , %-5s , %11s\n", "Category", " Rate", " Qty", "Revenue";

    my $catgs_revenue = 0.0;

    foreach $category (sort keys %categs)
    {
        $catgs_revenue += $categs{$category}{'Revenue'};

        printf "%-30s , %6.1f , %5d , %10.1f\n" , $category,
            $categs{$category}{'Revenue'} / $categs{$category}{'Qty'},
            $categs{$category}{'Qty'}, $categs{$category}{'Revenue'};
    }

    print '-' x 50 . "\n";
    printf ("%-37s,,,%10.1f\n" , "Total Revenue for All Categories", $catgs_revenue);
}

sub print_coordinator_table {
    printf "\n\n%-22s, %8s, %8s, %8s, %8s, %6s, %8s\n",
        "Coordinator Name", "#T-Nodes", "#M-Nodes", "#N-Nodes", "#S-Nodes",
        "#Nodes", "Revenue";

    foreach $coord (sort keys %coorddtls)
    {
        my $totnodes = $coorddtls{$coord}{'TCnt'} + $coorddtls{$coord}{'MCnt'} 
                     + $coorddtls{$coord}{'NCnt'} + $coorddtls{$coord}{'SCnt'};

        printf "%-22s, %8s, %8s, %8s, %8s, %6s, %8s\n",
            $coord, $coorddtls{$coord}{'TCnt'}, $coorddtls{$coord}{'MCnt'},
            $coorddtls{$coord}{'NCnt'}, $coorddtls{$coord}{'SCnt'},
            $totnodes, $coorddtls{$coord}{'Revenue'};
    }
}

sub print_coordinators_details {
    foreach $coord (sort keys %coorddtls)
    {
        my %cnts;
        my $totnodes = 0;

        foreach ('T', 'M', 'N', 'S')
        {
            $cnts{$_} = defined($coorddtls{$coord}{$_.'Cnt'}) ? $coorddtls{$coord}{$_.'Cnt'} : 0;
            $totnodes += $cnts{$_};
        }

        my $crev = defined($coorddtls{$coord}{'Revenue'}) ? $coorddtls{$coord}{'Revenue'} : 0;

        print "\nDetails for Coordinator: $coord\n";
        print "Number of hosts managed: " . ($totnodes) . ", Revenue: $crev\n";

        foreach ('T', 'M', 'N', 'S')
        {
            my $cdtls = \@{$coorddtls{$coord}{$_.'List'}};

            print "\nCType = $_ hosts ($cnts{$_})\n";
            for ($i = 0; $i < $cnts{$_}; $i++)
            {
                print $$cdtls[$i] . "\n";
            }
        }
    }
}

sub print_debug_information {
    printf("\n\nDEBUG Information\n\n");
    printf "%-22s , %-20s , %-11s , %s\n", "Node Name", "Category", "Project", "Customer";
    printf "%-22s , %-20s , %-11s , %s\n", "---------", "--------", "-------", "--------";

    foreach $node (sort {$nodecatg{$a} cmp $nodecatg{$b}} sort keys %nodecatg)
    {
        $nodecatg{$node} =~ s/^: //;
        $nodeproj{$node} =~ s/^: //;
        $nodecust{$node} =~ s/^: //;

        printf "%-22s , %-20s , %-11s , %s\n", $node, $nodecatg{$node}, $nodeproj{$node}, $nodecust{$node};
    }
}


while (<>)
{
	# Skip lines beginning with '#'.
	next if /^#/;

	chomp;
	my @fields = split /:/ ;

	# collect (hostname, os, charge, comments) fields.
	my ($nodename, $os, $revenue,$comments) = ($fields[0], $fields[2], $fields[9], $fields[17]);

	# Skip lines where charge is 666. Remember that 666 is a placeholder for
	# systems that we don't charge under this model.
	next if ($revenue == 666);

	my ($projid,$custname) = ($fields[7], $fields[12]);

	# In case someone enters the CType in lowercase.
	my ($ctype,$coordEPO) = (uc $fields[8], $fields[15]);

	if ($coordEPO eq "")
	{
		$coordEPO = "Missing Name";
	}

	if ($ctype eq "T")
	{
		$coorddtls{$coordEPO}{'TCnt'} += 1;
		push @{$coorddtls{$coordEPO}{'TList'}}, $nodename;
	}
	elsif ($ctype =~ /^[MNS]$/)
	{
		$coorddtls{$coordEPO}{$ctype.'Cnt'} += 1;
		push @{$coorddtls{$coordEPO}{$ctype.'List'}}, $nodename;
		$coorddtls{$coordEPO}{'Revenue'} += $revenue;
	}

	# Skip lines where CType is [T]ime&Materials.
	next if /:T:/;

	# 0 revenue records are needed. - 22/05/2012

	my $nodecount = 1, $rate = $revenue;
	$comments = ' ' . $comments;
	my $class = "";


	if ($revenue == 0)
	{
		$class = 'Zero Revenue (t&m)';
	}

	elsif ($comments =~ /LEASE/)
	{
		$class = 'SLA Lease Nodes';

		$nodename =~ s/_nodes$//;
		$nodedata{$nodename}{'Qty'} = $nodecount;
		$nodedata{$nodename}{'Revenue'} = $revenue;
	}

	elsif ($comments =~ / master /)
	{
		$class = 'SLA Cluster Master';
	}

	elsif ($nodename =~ s/_nodes(\d+)?$//)
	{
		$class = 'SLA Nodes';

		$comments =~ / (\d+) /;
		$nodecount = $1 != "" ? $1 : 1;
		$rate = ($revenue / $nodecount);

		$nodedata{$nodename}{'Qty'} += $nodecount;
		$nodedata{$nodename}{'Revenue'} += $revenue;
	}

	elsif ($nodename =~ /.als/ and $revenue > 0)
	{
		
	}

	elsif ($nodename =~ /_myrinet$/)
	{
		$class = 'SLA Myrinet';
	}

	elsif ($nodename =~ /_infiniband$/)
	{
		$class = 'SLA Infiniband';
	}

	elsif ($nodename =~ /_web$/)
	{
		$class = 'SLA Web';
	}

	elsif ($nodename =~ /_3ware$/)
	{
		$class = 'SLA 3ware';
	}

	elsif ($os =~ /OnTap/i and $revenue == 300)
	{
		$class = 'SLA Filer';
	}

	elsif ($nodename =~ /_gpfs$/ and $revenue == 300)
	{
		$class = 'SLA Gpfs';
	}

	elsif ($nodename =~ /_bluearc$/)
	{
		$class = 'SLA Bluearc';
	}

	elsif ($nodename =~ /riemann_storage$/)
	{
		$class = 'Riemann Storage';
	}

	elsif ($nodename =~ /snowbear[0-9]+$/)
	{
		$class = 'SLA Other';
	}


	elsif ($comments =~ /Linux VM Master$/i)
	{
		$class = 'SLA Linux VM Master';
	}

	elsif ($comments =~ /Linux VM$/i)
	{
		if ($revenue == 75)
		{
			$class = 'Linux VM Security';
		}
		else
		{
			$class = 'SLA Linux VM';
		}
	}

	elsif ($comments =~ /Amazon EC2/i and $revenue == 150)
	{
		$class = 'Amazon EC2';
	}

	elsif ($comments =~ /HPCS SMF client$/i and $revenue == 50 and $ctype eq "N")
	{
		$class = 'HPCS Linux SMF';
	}

	elsif ($comments =~ /(Solaris )?Software Farm$/i and $revenue == 60 and $ctype eq "N")
	{
		$class = 'Solaris Software Farm';
	}

	elsif ($comments =~ /SSLA\+HPCS SMF$/i and $revenue == 135)
	{
		$class = 'SSLA+HPCS SMF';
	}

	elsif ($comments =~ /vm small SLA/i and $revenue == 150)
	{
		$class = 'VM Small SLA';
	}

	elsif ($comments =~ /vm medium SLA/i and $revenue == 175)
	{
		$class = 'VM Medium SLA';
	}

	elsif ($comments =~ /vm large SLA/i and $revenue == 200)
	{
		$class = 'VM Large SLA';
	}	

	elsif ($comments =~ /vm small/i and $revenue == 25)
	{
		$class = 'VM Small';
	}	

	elsif ($comments =~ /vm medium/i and $revenue == 50)
	{
		$class = 'VM Medium';
	}	

	elsif ($comments =~ /vm large/i and $revenue == 100)
	{
		$class = 'VM Large';
	}

	elsif ($comments =~ /vm storage 20 SLA/i and $revenue == 10)
	{
		$class = 'VM Storage 20 SLA';
	}

	elsif ($comments =~ /vm storage 40 SLA/i and $revenue == 20)
	{
		$class = 'VM Storage 40 SLA';
	}

	elsif ($comments =~ /vm storage 80 SLA/i and $revenue == 40)
	{
		$class = 'VM Storage 80 SLA';
	}

	elsif ($comments =~ /VM Storage 20/i and $revenue == 15)
	{
		$class = 'VM Storage 20';
	}

	elsif ($comments =~ /VM Storage 40/i and $revenue == 30)
	{
		$class = 'VM Storage 40';
	}

	elsif ($comments =~ /vm storage 80/i and $revenue == 60)
	{
		$class = 'VM Storage 80';
	}

	elsif ($comments =~ /lsi/i and $revenue == 300)
	{
		$class = 'SLA LSI';     
	}

	elsif ($comments =~ /cluster master\+DTN/i and $revenue == 300)
	{
		$class = 'SLA Cluster Master + DTN';
	}

	elsif ($comments =~ /DTN/i and $revenue == 300)
	{
		$class = 'DTN';
	}

	elsif ($revenue == 55)
	{
		$class = 'SSLA group rate';
	}

	elsif ($revenue == 60)
	{
		$class = 'SLA SW Farm';
	}

	elsif ($revenue == 75)
	{
		$class = 'SSLA volume rate';
	}

	elsif ($revenue == 120)
	{
		$class = 'SSLA';
	}

	elsif ($revenue == 115)
	{
		$class = 'T&M';
	}

	elsif ($revenue == 120)
	{
		$class = 'SLA Security';
	}

	elsif ($revenue == 150)
	{
		$class = 'SLA Desktop std.';
	}

	elsif ($revenue == 200)
	{
		$class = 'SLA Server std.';
	}

	elsif ($revenue == 245)
	{
		$class = 'SLA Desktop';
	}

	elsif ($revenue == 285)
	{
		$class = 'SLA Server';
	}

	elsif ($revenue == 300)
	{
		$class = 'SLA Other';
	}

	# This is to catch new cases that need attention.

	if ($class eq "")
	{
		$class = "UNCLASSIFIED";
	}
	else
	{
		$categs{$class}{'Qty'} += $nodecount;
		$categs{$class}{'Revenue'} += $revenue;
	}

	$nodecatg{$fields[0]} .= ": $class";
	$nodecust{$fields[0]} .= ": $custname";
	$nodeproj{$fields[0]} .= ": $projid";

	if ($customer{$class} !~ /$custname/)
	{
		$customer{$class} .= "| $custname";
	}

	if ($project{$class} !~ /$projid/)
	{
		$project{$class} .= "| $projid";
	}
}

print_category_table();
print_node_table();
print_coordinator_table();
print_coordinators_details();
print_debug_information() if $debug == 1;
