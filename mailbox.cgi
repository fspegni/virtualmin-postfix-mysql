#!/usr/bin/perl 

require './virtualmin-postfix-mysql-lib.pl';

&ReadParse();

use WebminCore;

my $js = "<script type='text/javascript' src='/virtualmin-postfix-mysql/mailbox.js' ></script>\n";

$domain_name = $in{'dom'};

header("Mailboxes Configuration: $domain_name", undef, undef, undef,0,0,undef, $js);

# check whether it has been sent a form
my $command = "";
if (exists $in{command})
{
	$command = $in{command};
}

if ($command ne "")
{
	eval
	{
		if ($command eq "Save status")
		{
			my $new_status = (length($in{service_status}) > 0 ? 1 : 0);
			my $new_status_smtp = (length($in{service_status_smtp}) > 0 ? 1 : 0);
#			print "new status = '$new_status'";
			service_set_status($in{dom}, $new_status);
			service_set_status_smtp($in{dom}, $new_status_smtp);
		}
		elsif ($command eq "Save mailbox")
		{

			if ($in{password} eq "")
			{
				die("Password not specified");
			}

			if ($in{password} ne $in{password_repeat})
			{
				die("Passwords don't match, unable to continue");
			}
			mailbox_create($in{local}, $in{dom}, $in{password}, $in{quota});

		}
		elsif ($command eq "Save alias")
		{
			alias_create($in{new_alias}, $in{existing_address}, $in{dom});
		}
		elsif ($command eq "Delete mailbox")
		{
			
			for my $mailbox (split(" ",$in{mailbox}))
			{
				mailbox_delete($mailbox);
			}
		}
		elsif ($command eq "Delete alias")
		{
			alias_delete($in{aliases});
		}

		elsif ($command eq "Update mailbox")
		{
			if ($in{password} ne $in{password_repeat})
			{
				die("Passwords don't match, unable to continue");
			}

			my ($local,$domain) = split("@", $in{address});
			
			mailbox_update($local, $domain, $in{password}, $in{quota});
		}

		print "Command ".$command." terminated with success<br/>\n";
	}
	or do
	{
		print "<div class='error' style='color:red; font-weight:bold'>Error executing command ".$command.": ".$@."</div>\n";
	};
}


# show service status
my $service_status = service_get_status($in{dom});
my $service_status_smtp = service_get_status_smtp($in{dom});

#print "service status = '$service_status'";

print ui_table_start("Enable/disable sending mail", undef, 1);
print ui_form_start("", "post", undef);

$label_status_smtp = "<strong>yes</strong>/no";
if (! $service_status_smtp) {
	$label_status_smtp = "yes/<strong>no</strong>";
}
print ui_table_row("Can send:",
	ui_checkbox("service_status_smtp", "1", $label_status_smtp, $service_status_smtp));
$label_status = "<strong>yes</strong>/no";
if (! $service_status) {
	$label_status = "yes/<strong>no</strong>";
}
print ui_table_row("Can receive:", 
	ui_checkbox("service_status", "1", $label_status, $service_status));
print ui_table_row(ui_form_end([ ['command', "Save status"] ]));

# add a mailbox

print ui_table_start('Add a mailbox', undef,1);
print ui_form_start("","post",undef,
	"onSubmit=\"return check_mailbox_create('form_mailbox_create','local','password','password_repeat','quota')\" name='form_mailbox_create'");

print ui_table_row("Address:",
	ui_textbox("local",$local,20,undef,undef,"id='local'")."\@".$in{dom});
print ui_table_row("Password:",
	ui_password("password",$pwd,20,undef,undef,"id='password'"));
print ui_table_row("Repeat password:",
	ui_password("password_repeat",$pwd,20,undef,undef,"id='password_repeat'"));
print ui_table_row("Quota:",
	ui_textbox("quota",$quota,10,undef,undef,"id='quota'")." MB");

print ui_table_row(ui_form_end([ ['command', "Save mailbox"] ]));

print ui_table_end();

# delete a mailbox
print ui_table_start('Delete a mailbox', undef, 1);
print ui_form_start(undef,"post");


my $values = mailbox_get_addresses($in{dom});

my $addresses = [ ];
my $quotas = {};
my $js_quotas = "<script type='text/javascript'>\nvar quotas = new Array();\n";
foreach my $addr_info (@$values)
{
	my $addr = $addr_info->{"address"};
	my $quota = $addr_info->{"quota"};
	push(@$addresses, $addr);
	$quotas->{$addr} = $quota;

	$js_quotas .= "quotas['".$addr."'] = '".$quota."';\n";
}
$js_quotas .= "</script>\n";

print $js_quotas;

print ui_multi_select("mailbox", [ ], $addresses, 10,0,0,"All addresses","To be delete");

print ui_form_end([ ['command', "Delete mailbox"] ]);
print ui_table_end();

# reset password
print ui_table_start('Update a mailbox', undef,1);
print ui_form_start(undef,"post", undef, "onSubmit='return check_mailbox_reset(\"address\", \"quota_edit\");'");

$edit_addresses = [ "---" ];
push(@$edit_addresses, @$addresses);

print ui_table_row("Address:",
	ui_select("address", undef, $edit_addresses,"","","","","id='address' onchange=handleEditMailbox('address','quota_edit');" ));

print ui_table_row("Password:",
	ui_password("password",$pwd,20));
print ui_table_row("Repeat password:",
	ui_password("password_repeat",$pwd,20));
print ui_table_row("Quota:",
	ui_textbox("quota",$quota,10,"","","id='quota_edit'")." MB");

print ui_form_end([ ['command', "Update mailbox"] ]);
print ui_table_end();

print "</td><td></td></tr></table>\n";

# add an alias
print ui_table_start('Add an alias', undef,1);
print ui_form_start("","post",undef,
	"onSubmit=\"return check_alias_create('form_alias_create','new_alias','existing_address')\" name='form_alias_create'");

print ui_table_row("New alias:",
	ui_textbox("new_alias",$new_alias,20,undef,undef,"id='new_alias'")."\@".$in{dom});
print ui_table_row("Existing address:",
	ui_textbox("existing_address",$existing_address,20,undef,undef,"id='existing_address'"));
print ui_table_row(ui_form_end([ ['command', "Save alias"] ]));

print ui_table_end();



# delete alias
print ui_table_start('Delete an alias', undef, 1);
print ui_form_start(undef,"post", undef, "onSubmit='return check_alias_delete(\"aliases\");'");

my $values = mailbox_get_aliases($in{dom});
my $aliases = [ "---" ]; #[ "cua","aaa","bb"];
my $js_aliases = "<script type='text/javascript'>\nvar aliases = new Array();\n";

foreach my $alias_info (@$values)
{
	my $addr = $alias_info->{"address"};
	my $goto = $alias_info->{"goto"};

	push(@$aliases, $addr);
	$js_aliases .= "aliases['".$addr."'] = '".$goto."';"
	
}
$js_aliases .= "</script>\n";


print $js_aliases;

print ui_table_row("Alias:",
	ui_select("aliases", undef, $aliases,"","","","","id='aliases' onchange='handleChangeAlias(\"aliases\", \"goto_label\")'")); 
print ui_table_row("Goto:",
	ui_textbox("goto", $goto, 20, undef,undef,"id='goto_label' readonly"));


print ui_form_end([ ['command', "Delete alias"] ]);
print ui_table_end();



ui_print_footer('/', 'Webmin index');
