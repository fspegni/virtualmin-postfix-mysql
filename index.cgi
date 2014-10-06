#!/usr/bin/perl
# Show links to domain for which the module is enabled, and liks to domains
# for which it isn't.

require './virtualmin-postfix-mysql-lib.pl';
&ReadParse();
#&foreign_require("apache", "apache-lib.pl");

# Get domain and directories
if ($in{'dom'}) {
	$d = &virtual_server::get_domain($in{'dom'});
	&virtual_server::can_edit_domain($d) || &error($text{'index_ecannot'});
	}
#@dirs = &htaccess_htpasswd::list_directories();
#@dirs = grep { &can_directory($_->[0], $d) } @dirs;

&ui_print_header($d ? &virtual_server::domain_in($d) : "Configured domains",
		 $text{'index_title'}, "", "intro", 0, 1);

$domains = domain_get_list();

print "<ul>\n";
foreach $dom (@$domains) {
	my $domain_name = $dom->{"domain"};
	my $link = "/virtualmin-postfix-mysql/mailbox.cgi?dom=$domain_name";
	my $send = $dom->{"active_smtp"} == 1 ? "<font color='green'>YES</font>" : "<font color='red'>no</font>";
	my $recv = $dom->{"active"} == 1 ? "<font color='green'>YES</font>" : "<font color='red'>no</font>";
	print "<li><a href='$link'>$domain_name</a> (send:$send, receive: $recv)</li>";
}
print "</ul>\n";

### Build table of directories
##@table = ( );
##foreach $dir (@dirs) {
##	$conf = &apache::get_htaccess_config(
##		"$dir->[0]/$htaccess_htpasswd::config{'htaccess'}");
##	$desc = &apache::find_directive("AuthName", $conf, 1);
##	$users = $dir->[2] == 3 ?
##		&htaccess_htpasswd::list_digest_users($dir->[1]) :
##		&htaccess_htpasswd::list_users($dir->[1]);
##	push(@table, [
##		{ 'type' => 'checkbox', 'name' => 'd', 'value' => $dir->[0] },
##		$d ? &remove_public_html($dir->[0], $d) : $dir->[0],
##		$desc,
##		scalar(@$users),
##		]);
##	}
##
### Render table of directories
##print &ui_form_columns_table(
##	"delete.cgi",
##	[ [ "delete", $text{'index_delete'} ] ],
##	1,
##	[ [ "add_form.cgi?dom=".&urlize($in{'dom'}), $text{'index_add'} ] ],
##	[ [ "dom", $in{'dom'} ] ],
##	[ "", $text{'index_dir'}, $text{'index_desc'}, $text{'index_users'} ],
##	undef,
##	\@table,
##	undef,
##	0,
##	undef,
##	$text{'index_none'});
##
# Show button to find more
if ($d) {
	print &ui_hr();
	print &ui_buttons_start();
	print &ui_buttons_row("find.cgi", $text{'index_find'},
			      &text('index_finddesc', "<tt>$d->{'home'}</tt>"),
			      &ui_hidden("dom", $in{'dom'}));
	print &ui_buttons_end();
	}

if ($d) {
	&ui_print_footer($d ? &virtual_server::domain_footer_link($d) : ( ),
			 "/virtual-server/",
			 $virtual_server::text{'index_return'});
	}
else {
	&ui_print_footer("/", $text{'index'});
	}

