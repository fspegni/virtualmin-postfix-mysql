# Common functions for apache configuration

BEGIN { push(@INC, ".."); };
use WebminCore;
use DBI;
use File::Path;


&init_config();
&foreign_require("virtual-server", "virtual-server-lib.pl");

my $vmail_home="/var/vmail/";

sub crypt_sha512 
{
    ($theword) = @_;
    srand(time); # random seed

    @saltchars=(a..z,A..Z,0..9,'.','/'); # valid salt chars
    
    my $saltLength = 8;
    my $salt = "";
    for (my $i=0; $i<$saltLength; $i++)
    {
        $salt .= $saltchars[int(rand($#saltchars+1))];
    }

    return crypt($theword, '$6$'.$salt.'$');
}

sub service_get_status
{
    ($domain) = @_;

    my $db_name = $config{'db_name'};
    my $db_user = $config{'db_user'};
    my $db_password = $config{'db_password'};
    my $db_host = $config{'db_host'};
    my $db_port = $config{'db_port'};

    my $dbh = DBI->connect("dbi:mysql:$db_name:$db_host:$db_port",$db_user,$db_password,
        {"PrintError"=>1,"RaiseError"=>1}) || die "could not connect to database";
    
    my $query = "SELECT active FROM domain WHERE domain=? LIMIT 0,1";
    
#    print $query."\n";
    my $sth = $dbh->prepare($query);
    $sth->execute($domain);

    ($curr_status) = $sth->fetchrow_array();

    $sth->finish();
    
    $dbh->disconnect();

    return $curr_status;
}

sub service_get_status_smtp
{
    ($domain) = @_;

    my $db_name = $config{'db_name'};
    my $db_user = $config{'db_user'};
    my $db_password = $config{'db_password'};
    my $db_host = $config{'db_host'};
    my $db_port = $config{'db_port'};

    my $dbh = DBI->connect("dbi:mysql:$db_name:$db_host:$db_port",$db_user,$db_password,
        {"PrintError"=>1,"RaiseError"=>1}) || die "could not connect to database";
    
    my $query = "SELECT active_smtp FROM domain WHERE domain=? LIMIT 0,1";
    
#    print $query."\n";
    my $sth = $dbh->prepare($query);
    $sth->execute($domain);

    ($curr_status_smtp) = $sth->fetchrow_array();

    $sth->finish();
    
    $dbh->disconnect();

    return $curr_status_smtp;
}



sub service_set_status
{
    ($domain, $enabled) = @_;
    
    my $db_name = $config{'db_name'};
    my $db_user = $config{'db_user'};
    my $db_password = $config{'db_password'};

    my $dbh = DBI->connect("dbi:mysql:$db_name",$db_user,$db_password,
        {"PrintError"=>1,"RaiseError"=>1}) || die "could not connect to database";
    
    my $query = "
        UPDATE domain SET active=? WHERE domain=?
    ";
    
#    print $query."\n";
    my $sth = $dbh->prepare($query);
    my $numInserted = $sth->execute($enabled, $domain);
    $sth->finish();
    
    $dbh->disconnect();
}

sub service_set_status_smtp
{
    ($domain, $enabled) = @_;
    
    my $db_name = $config{'db_name'};
    my $db_user = $config{'db_user'};
    my $db_password = $config{'db_password'};

    my $dbh = DBI->connect("dbi:mysql:$db_name",$db_user,$db_password,
        {"PrintError"=>1,"RaiseError"=>1}) || die "could not connect to database";
    
    my $query = "
        UPDATE domain SET active_smtp=? WHERE domain=?
    ";
    
#    print $query."\n";
    my $sth = $dbh->prepare($query);
    my $numInserted = $sth->execute($enabled, $domain);
    $sth->finish();
    
    $dbh->disconnect();
}


sub mailbox_get_aliases
{
    my ($domain) = @_;

    my $query = "
        SELECT address,goto FROM alias WHERE domain=?
    ";

    my $db_name = $config{'db_name'};
    my $db_user = $config{'db_user'};
    my $db_password = $config{'db_password'};

    my $dbh = DBI->connect("dbi:mysql:$db_name",$db_user,$db_password,
        {"PrintError"=>1,"RaiseError"=>1}) || die "could not connect to database";

    $sth = $dbh->prepare($query);
    my $numRows = $sth->execute($domain);

    my $res = [];
    while (($address, $goto) = $sth->fetchrow_array())
    {
# TODO return quota information
        push(@$res, { "address" => $address, "goto" => $goto } );
    }

    $sth->finish();
    $dbh->disconnect();

    return $res;
}

sub mailbox_get_addresses
{
    my ($domain) = @_;

    my $db_name = $config{'db_name'};
    my $db_user = $config{'db_user'};
    my $db_password = $config{'db_password'};

    my $dbh = DBI->connect("dbi:mysql:$db_name",$db_user,$db_password,
        {"PrintError"=>1,"RaiseError"=>1}) || die "could not connect to database";
    
    my $query = "
        SELECT CONCAT(local_part,CONCAT('\@', ?)) as mailaddress, quota FROM mailbox WHERE domain=?
    ";
    
    $sth = $dbh->prepare($query);
    my $numRows = $sth->execute($domain, $domain);

    my $res = [];
    my $currAddress;
    while (($currAddress, $quota) = $sth->fetchrow_array())
    {
# TODO return quota information
        push(@$res, { "address" => $currAddress, "quota" => $quota } );
    }

    $sth->finish();
    $dbh->disconnect();

    return $res;
}

sub alias_create
{
    my ($local, $goto, $domain) = @_;

    my $address = $local."@".$domain;

    my $db_name = $config{'db_name'};
    my $db_user = $config{'db_user'};
    my $db_password = $config{'db_password'};

    my $dbh = DBI->connect("dbi:mysql:$db_name",$db_user,$db_password,
        {"PrintError"=>1,"RaiseError"=>1}) || die "could not connect to database";
    
    my $query = "
        INSERT INTO alias(address,goto,domain,created,modified) 
        VALUES (?,?,?,NOW(),NOW());
    ";
    
    my $sth = $dbh->prepare($query);
    my $numInserted = $sth->execute($address, $goto, $domain);
    $sth->finish();
    
    $dbh->disconnect();
}

sub mailbox_create
{
    my ($local_part, $domain, $mbox_pwd, $quota) = @_;
    # convert quota from MB to B
    $quota = $quota * 1024 * 1024; 

    if ($local_part eq "")
    {
        die("local part cannot be empty");
    }

    if ($domain eq "") 
    {
        die("domain cannot be empty");
    }

    if ($mbox_pwd eq "") 
    {
        die("password cannot be empty");
    }


#    print "local=".$local_part.",domain=".$domain.",pwd=".$mbox_pwd;

    my $mailaddress = $local_part."@".$domain;
    my $vmail_dir = $domain."/".$local_part;
    my $vmail_dir_full = $vmail_home.$vmail_dir;
    # store info in db

    my $db_name = $config{'db_name'};
    my $db_user = $config{'db_user'};
    my $db_password = $config{'db_password'};

#    print "address=".$mailaddress.",user=".$db_user.",pwd=".$db_password.",d=".$db_name;
    my $dbh = DBI->connect("dbi:mysql:$db_name",$db_user,$db_password,
        {"PrintError"=>1,"RaiseError"=>1}) || die "could not connect to database";
    
    my $query = "
        INSERT INTO mailbox(username,password,maildir,local_part,domain,quota,created,modified) 
        VALUES (?,?,?,?,?,?,NOW(),NOW());
    ";
    
#    print $query."\n";
    my $sth = $dbh->prepare($query);
    my $mbox_pwd_crypt=crypt_sha512($mbox_pwd);
    my $numInserted = $sth->execute($mailaddress, $mbox_pwd_crypt, $vmail_dir, 
	$local_part, $domain, $quota);
    $sth->finish();
    #$dbh->do($query);
    
    $dbh->disconnect();
    
    # prepare file system
#    my $vmail_dir="$vmail_home/$domain/$local_part";
    
#    print "arrivo qui!";
#    if (! -d $vmail_dir_full)
#    {
#        mkdir $vmail_dir_full || print "Unable to create $vmail_dir_full";
#    }
#    else
#    {
#        print "Directory $vmail_dir already exists";
#    }
}

sub alias_delete
{
    my ( $address, $goto ) = split(/[ ]*->[ ]*/, @_[0]);

    if ($address eq "")
    {
        die("alias address cannot be empty");
    }

    my ( $local, $domain ) = split("\@",$address);

    if ($domain eq "") 
    {
        die("domain cannot be empty");
    }

    my $db_name = $config{'db_name'};
    my $db_user = $config{'db_user'};
    my $db_password = $config{'db_password'};

    my $dbh = DBI->connect("dbi:mysql:$db_name",$db_user,$db_password,
        {"PrintError"=>1,"RaiseError"=>1}) || die "could not connect to database";

    my $query = "DELETE FROM alias WHERE address=? AND domain=?";
       
    $sth = $dbh->prepare($query);
    my $numDeleted = $sth->execute($address,$domain);
    $sth->finish();
    $dbh->disconnect();

    if ($numDeleted != 1)
    {
        die("Expected to delete 1 element. Deleted: ".$numDeleted);
    }
}

sub mailbox_delete
{
    my ( $local, $domain ) = split("\@",@_[0]);

    if ($local eq "")
    {
        die("local part cannot be empty");
    }

    if ($domain eq "") 
    {
        die("domain cannot be empty");
    }


#    my $deletemailbox = getFullAddress();
#    print "local=".$local.",domain=".$domain;
#
    my $db_name = $config{'db_name'};
    my $db_user = $config{'db_user'};
    my $db_password = $config{'db_password'};

    my $dbh = DBI->connect("dbi:mysql:$db_name",$db_user,$db_password,
        {"PrintError"=>1,"RaiseError"=>1}) || die "could not connect to database";
#    
#    my $maildir = "";### TODO finire da qui
    my $query_maildir = "SELECT maildir FROM mailbox WHERE local_part=? AND domain=?";
    my $sth = $dbh->prepare($query_maildir);
    my $numMaildir = $sth->execute($local, $domain);
    
    if ($numMaildir != 1)
    {
        $sth->finish();
        $dbh->disconnect();
        die("No maildir or too many maildir found. Expected 1, found ".
		$numMaildir);
    }

    my @row = $sth->fetchrow();
    my $maildir = @row[0];
#    print "maildir=".$maildir;
    $sth->finish();
#    
#    print "maildir = $maildir";
#    
    if ($maildir ne "")
    {
        my $query = "DELETE FROM mailbox WHERE local_part=? AND domain=?";
        
        #print $query."\n";
        
    $sth = $dbh->prepare($query);
    my $numDeleted = $sth->execute($local,$domain);
    $sth->finish();
#        $dbh->do($query);
#        
        $dbh->disconnect();

    if ($numDeleted != 1)
    {
        die("Expected to delete 1 element. Deleted: ".$numDeleted);
    }
#        
#        # delete vmail for domain
#        
#        my $vmail_home="/var/vmail";
        my $maildir_full = $vmail_home.$maildir;
        if (-d $maildir_full)
        {
            rmtree($maildir_full) || die("Unable to remove $maildir_full");
        }
    }
}

sub mailbox_update
{
    my ($local, $domain, $pwd, $quota) = @_;
    # convert quota from MB to B
    $quota = $quota * 1024 * 1024; 

    if ($local eq "")
    {
        die("local part cannot be empty");
    }

    if ($domain eq "") 
    {
        die("domain cannot be empty");
    }

#    if ($pwd eq "") 
#    {
#        die("password cannot be empty");
#    }

    my $db_name = $config{'db_name'};
    my $db_user = $config{'db_user'};
    my $db_password = $config{'db_password'};

    my $dbh = DBI->connect("dbi:mysql:$db_name",$db_user,$db_password,
        {"PrintError"=>1,"RaiseError"=>1}) || die "could not connect to database";
 
#	print "pwd = '$pwd'";
    my $sth = undef;
    my $pwd_crypt = undef;
    my $numInserted = undef;

    if ($pwd ne "")
    {
   
        my $query = "UPDATE mailbox SET password = ?, quota = ? WHERE local_part = ? AND domain = ?";
        
        $sth = $dbh->prepare($query);
        my $pwd_crypt = crypt_sha512($pwd);
        $numInserted = $sth->execute($pwd_crypt, $quota, $local, $domain);
    }
    else
    {
        my $query = "UPDATE mailbox SET quota = ? WHERE local_part = ? AND domain = ?";
        $sth = $dbh->prepare($query);
        $numInserted = $sth->execute($quota, $local, $domain);
    }
    $sth->finish();
    #$dbh->do($query);
    
    $dbh->disconnect();
 
}

sub domain_create
{
    my ( $newdomain ) = @_; #$self->{_name};
    # store info in db
    
    my $db_name = $config{'db_name'};
    my $db_user = $config{'db_user'};
    my $db_password = $config{'db_password'};

    my $dbh = DBI->connect("dbi:mysql:$db_name",$db_user,$db_password,
        {"PrintError"=>1,"RaiseError"=>1}) || die "could not connect to database";
    
    # create the domain
    my $query = "INSERT INTO domain(domain,created,modified,transport) VALUES (?,NOW(),NOW(),'virtual')";
    
    #print $query."\n";
    #print "new domain = ".$newdomain."\n";
    
    $sth = $dbh->prepare($query);
    $numInserted = $sth->execute($newdomain);
    $sth->finish();

    #enable any existing mailbox
    my $query = "UPDATE mailbox SET active = '1' WHERE domain = ?";
    
    #print $query."\n";
    
    $sth = $dbh->prepare($query);
    $numInserted = $sth->execute($newdomain);
    $sth->finish();
 
    $dbh->disconnect();
    
    # prepare file system
#    my $vmail_home="/var/vmail/";
#    my $vmail_dir="$vmail_home/$newdomain";
#    
#    if (! -d $vmail_dir)
#    {
#        mkdir $vmail_dir || die("Unable to create $vmail_dir");
#    }
#

}

sub domain_delete
{
#    my $deletedomain = $self->{_name};
    my ( $deletedomain, $deleteAlsoMailboxes ) = @_;

    my $db_name = $config{'db_name'};
    my $db_user = $config{'db_user'};
    my $db_password = $config{'db_password'};

    my $dbh = DBI->connect("dbi:mysql:$db_name",$db_user,$db_password,
        {"PrintError"=>1,"RaiseError"=>1}) || die "could not connect to database";
    
    my $query = "";
    
    if ($deleteAlsoMailboxes)
    {
        $query = "DELETE FROM domain WHERE domain=?";
    }
    else
    {
        $query = "DELETE FROM mailbox.*, domain.* FROM domain INNER JOIN mailbox ".
                "ON mailbox.domain = domain.domain ".
                "WHERE domain.domain = ?";
    }
    
    #print $query."\n";
    
    $sth = $dbh->prepare($query);
    $numDeleted = $sth->execute($deletedomain);
    $sth->finish();

    # disable any existing mailbox
    my $query = "UPDATE mailbox SET active = '0' WHERE domain = ?";
    
#    print $query."\n";
    
    $sth = $dbh->prepare($query);
    $numInserted = $sth->execute($deletedomain);
    $sth->finish();
 
    
    $dbh->disconnect();
    
    # delete vmail for domain
    
#    my $vmail_home="/var/vmail";
    my $vmail_dir="$vmail_home/$deletedomain";
    if (-d $vmail_dir)
    {
        rmtree($vmail_dir) || die("Unable to remove $vmail_dir");
    }
    
}


sub domain_set_enabled
{
    my ( $newdomain, $isEnabled ) = @_; #$self->{_name};

    # normalize $isEnabled to 0 or 1
    $isEnabled = ($isEnabled != 0);

#    print "is enabled: $isEnabled\n";

    # store info in db
    my $db_name = $config{'db_name'};
    my $db_user = $config{'db_user'};
    my $db_password = $config{'db_password'};

    my $dbh = DBI->connect("dbi:mysql:$db_name",$db_user,$db_password,
        {"PrintError"=>1,"RaiseError"=>1}) || die "could not connect to database";
    
    # set domain active/inactive
    my $query = "UPDATE domain SET active = ? WHERE domain = ?";
    
#    print $query."\n";
    
    $sth = $dbh->prepare($query);
    $numInserted = $sth->execute($isEnabled, $newdomain);
    $sth->finish();

    # set mailboxes active/inactive
    my $query = "UPDATE mailbox SET active = ? WHERE domain = ?";
    
#    print $query."\n";
    
    $sth = $dbh->prepare($query);
    $numInserted = $sth->execute($isEnabled, $newdomain);
    $sth->finish();
    
    $dbh->disconnect();
    
    # prepare file system
#    my $vmail_home="/var/vmail/";
    my $vmail_dir="$vmail_home/$newdomain";
    
#    if (! -d $vmail_dir)
#    {
#        mkdir $vmail_dir || die("Unable to create $vmail_dir");
#    }
#

}

sub domain_get_list
{
#    my ($domain) = @_;

    my $db_name = $config{'db_name'};
    my $db_user = $config{'db_user'};
    my $db_password = $config{'db_password'};
    my $db_host = $config{'db_host'};
    my $db_port = $config{'db_port'};

    my $dbh = DBI->connect("dbi:mysql:$db_name:$db_host:$db_port",$db_user,$db_password,
        {"PrintError"=>1,"RaiseError"=>1}) || die "could not connect to database";
    
    # TODO understand if the domain with name ALL can be deleted from db
    my $query = "SELECT domain,active,active_smtp FROM domain WHERE domain != 'ALL' ORDER BY domain";
    
    $sth = $dbh->prepare($query);
    my $numRows = $sth->execute();

    my $res = [];
    my $currAddress;
    while (($domain, $active, $active_smtp) = $sth->fetchrow_array())
    {
        push(@$res, { "domain" => $domain, "active" => $active, "active_smtp" => $active_smtp } );
    }

    $sth->finish();
    $dbh->disconnect();

    return $res;
}



1;
