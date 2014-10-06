# Defines functions for this feature

require 'virtualmin-postfix-mysql-lib.pl';

$input_name = $module_name;
$input_name =~ s/[^A-Za-z0-9]/_/g;

# feature_name()
# Returns a short name for this feature
sub feature_name
{
#return $text{'feat_name'};
	return "Virtualmin plugin for mailboxes configured with MySQL";
}

# feature_losing(&domain)
# Returns a description of what will be deleted when this feature is removed
sub feature_losing
{
	#return $text{'feat_losing'};
	return "All the mailboxes associated with this domain are going to be deleted..."; #"losing feature ...";
}

# feature_disname(&domain)
# Returns a description of what will be turned off when this feature is disabled
sub feature_disname
{
	#return $text{'feat_disname'};
	return "Mailboxes associated with this domain are going to be disabled but NOT deleted ...";
}

# feature_label(in-edit-form)
# Returns the name of this feature, as displayed on the domain creation and
# editing form
sub feature_label
{
	#return $text{'feat_label'};
	return "Manage Mailboxes with MySQL authentication";
}

#sub feature_hlink
#{
#return "label";
#}

# feature_check()
# Returns undef if all the needed programs for this feature are installed,
# or an error message if not
sub feature_check
{
#return &check_awstats();
return undef;
}

# feature_depends(&domain)
# Returns undef if all pre-requisite features for this domain are enabled,
# or an error message if not
sub feature_depends
{
#return $text{'feat_edepweb'} if (!$_[0]->{'web'});
#return $text{'feat_edepunix'} if (!$_[0]->{'unix'} && !$_[0]->{'parent'});
#return $text{'feat_edepdir'} if (!$_[0]->{'dir'});
return undef;
}

# feature_clash(&domain, [field])
# Returns undef if there is no clash for this domain for this feature, or
# an error message if so
sub feature_clash
{
#if (!$_[1] || $_[1] eq 'dom') {
#	return -r "$config{'config_dir'}/awstats.$_[0]->{'dom'}.conf" ?
#		$text{'feat_clash'} : undef;
#	}
return undef;
}

# feature_suitable([&parentdom], [&aliasdom], [&subdom])
# Returns 1 if some feature can be used with the specified alias and
# parent domains
sub feature_suitable
{
local ($parentdom, $aliasdom, $subdom) = @_;
return $aliasdom || $subdom ? 0 : 1;	# not for alias or sub domains
#return 1;
#return 0;
}

# feature_import(domain-name, user-name, db-name)
# Returns 1 if this feature is already enabled for some domain being imported,
# or 0 if not
sub feature_import
{
local ($dname, $user, $db) = @_;
return -r "$config{'config_dir'}/awstats.$dname.conf" ? 1 : 0;
}

# feature_enable(&domain)
# Called when this feature is enabled, with the domain object as a parameter
sub feature_enable
{
	my ($d) = @_;
	&$virtual_server::first_print("Domain ".$d->{dom}." prepares to accept new mailboxes ...");

	domain_set_enabled($d->{dom}, 1);

	return 1;
}


# feature_disable(&domain)
# Called when this feature is disabled, with the domain object as a parameter
sub feature_disable
{
	my ($d) = @_;
	&$virtual_server::first_print("Domain ".$d->{dom}." halts the mailbox service ...");

	domain_set_enabled($d->{dom},0);

	return 1;
}



# feature_setup(&domain)
# Called when this feature is added, with the domain object as a parameter
sub feature_setup
{
	my ($d) = @_;
	&$virtual_server::first_print("Domain ".$d->{dom}." prepares to accept new mailboxes ...");

	domain_create($d->{dom});

	return 1;
}

# feature_delete(&domain)
# Called when this feature is removed, with the domain object as a parameter
sub feature_delete
{
	my ($d) = @_;
	&$virtual_server::first_print("Domain ".$d->{dom}." is deleting all the mailboxes and disabling the service ...");

	domain_delete($d->{dom}, 1);

	return 1;
}


# feature_modify(&domain, &olddomain)
# Called when a domain with this feature is modified
sub feature_modify
{
	my ($d) = @_;
	&$virtual_server::first_print("Mailboxes are going to be created (fake)...");

	#print "d= ".$d." ...\n";
	# domain_create($d->{dom});

	return 1;
}

# feature_setup_alias(&domain, &alias)
# Called when an alias of this domain is created, to perform any required
# configuration changes. Only useful when the plugin itself does not implement
# an alias feature.
sub feature_setup_alias
{
#local ($d, $alias) = @_;
#
## Add the alias to the .conf files
#&$virtual_server::first_print(&text('feat_setupalias', $d->{'dom'}));
#&symlink_logged(&get_config_file($d->{'dom'}),
#		&get_config_file($alias->{'dom'}));
#&symlink_logged(&get_config_file($d->{'dom'}),
#		&get_config_file("www.".$alias->{'dom'}));
#
## Add to HostAliases
#&lock_file(&get_config_file($d->{'dom'}));
#local $conf = &get_config($d->{'dom'});
#local $ha = &find_value("HostAliases", $conf);
#$ha .= " REGEX[".quotemeta($alias->{'dom'})."\$]";
#&save_directive($conf, $d->{'dom'}, "HostAliases", $ha);
#&flush_file_lines(&get_config_file($d->{'dom'}));
#&unlock_file(&get_config_file($d->{'dom'}));
#
## Link up existing data files
#local $dirdata = &find_value("DirData", $conf);
#&link_domain_alias_data($d->{'dom'}, $dirdata, $d->{'user'});
#&$virtual_server::second_print($virtual_server::text{'setup_done'});
#
return 1;
}

# feature_delete_alias(&domain, &alias)
# Called when an alias of this domain is deleted, to perform any required
# configuration changes. Only useful when the plugin itself does not implement
# an alias feature.
sub feature_delete_alias
{
#local ($d, $alias) = @_;
#
## Remove the alias's .conf file
#&$virtual_server::first_print(&text('feat_deletealias', $d->{'dom'}));
#&unlink_logged(&get_config_file($alias->{'dom'}));
#&unlink_logged(&get_config_file("www.".$alias->{'dom'}));
#
## Remove alias from HostAliases
#&lock_file(&get_config_file($d->{'dom'}));
#local $conf = &get_config($d->{'dom'});
#local $ha = &find_value("HostAliases", $conf);
#local $qd = quotemeta($alias->{'dom'});
#$ha =~ s/\s*REGEX\[\Q$qd\E\$\]//;
#&save_directive($conf, $d->{'dom'}, "HostAliases", $ha);
#&flush_file_lines(&get_config_file($d->{'dom'}));
#&unlock_file(&get_config_file($d->{'dom'}));
#
## Remove data symlinks
#local $dirdata = &find_value("DirData", $conf);
#&unlink_domain_alias_data($alias->{'dom'}, $dirdata);
#&$virtual_server::second_print($virtual_server::text{'setup_done'});
#
return 1;
}

# feature_webmin(&domain, &other)
# Returns a list of webmin module names and ACL hash references to be set for
# the Webmin user when this feature is enabled
sub feature_webmin
{
#local @doms = map { $_->{'dom'} } grep { $_->{$module_name} } @{$_[1]};
#if (@doms) {
#	return ( [ $module_name,
#		   { 'create' => 0,
#		     'user' => $_[0]->{'user'},
#		     'editlog' => 0,
#		     'editsched' => !$config{'noedit'},
#		     'domains' => join(" ", @doms),
#		     'noconfig' => 1,
#		   } ] );
#	}
#else {
#	return ( );
#	}
local ($d, $all) = @_;
my @fdoms = grep { $_->{$module_name} } @$all;
if (@fdoms) {
  return ( [ $module_name, { 'doms' => join(" ", @fdoms) } ] );
  }
else {
  return ( );
  }
}

# feature_links(&domain)
# Returns an array of link objects for webmin modules for this feature
sub feature_links
{
local ($d) = @_;
return ( # Link to either view a report, or edit settings
	 { 'mod' => $module_name,
           'desc' => "Configure Mailboxes", #$text{'links_view'},
           'page' => 'mailbox.cgi?dom='.&urlize($d->{'dom'}),
	   'cat' => 'services',
         },
#	 # Link to edit AWstats config for this domain
#	 { 'mod' => $module_name,
#           'desc' => "Foo extension 2", #$text{'links_config'},
#           'page' => 'config.cgi?dom='.&urlize($d->{'dom'}),
#	   'cat' => 'services',
#         },
       );
}

# feature_backup(&domain, file, &opts, &all-opts)
# Copy the awstats config file for the domain
sub feature_backup
{
#local ($d, $file, $opts) = @_;
#&$virtual_server::first_print($text{'feat_backup'});
#local $cfile = "$config{'config_dir'}/awstats.$d->{'dom'}.conf";
#if (-r $cfile) {
#	&copy_source_dest($cfile, $file);
#	&$virtual_server::second_print($virtual_server::text{'setup_done'});
#	return 1;
#	}
#else {
#	&$virtual_server::second_print($text{'feat_nofile'});
#	return 0;
#	}
}

# feature_restore(&domain, file, &opts, &all-opts)
# Called to restore this feature for the domain from the given file
sub feature_restore
{
#local ($d, $file, $opts) = @_;
#local $ok = 1;
#
## Restore the config file
#&$virtual_server::first_print($text{'feat_restore'});
#local $cfile = "$config{'config_dir'}/awstats.$d->{'dom'}.conf";
#&lock_file($cfile);
#if (&copy_source_dest($file, $cfile)) {
#	&unlock_file($cfile);
#	&$virtual_server::second_print($virtual_server::text{'setup_done'});
#	}
#else {
#	&$virtual_server::second_print($text{'feat_nocopy'});
#	$ok = 0;
#	}
#
## Re-setup awstats.pl, lib, plugins and icons, as the old paths in the backup
## probably don't match this system
#&setup_awstats_commands($d);
#
#return $ok;
return 1;
}

sub feature_backup_name
{
return $text{'feat_backup_name'};
}

sub feature_validate
{
local ($d) = @_;

## Make sure config file exists
#local $cfile = "$config{'config_dir'}/awstats.$d->{'dom'}.conf";
#-r $cfile || return &text('feat_evalidate', "<tt>$cfile</tt>");
#
## Check for logs directory
#-d "$d->{'home'}/awstats" || return &text('feat_evalidatedir', "<tt>$d->{'home'}/awstats</tt>");
#
## Check for cron job
#if (!$config{'nocron'}) {
#	&foreign_require("cron", "cron-lib.pl");
#	local $job = &find_cron_job($d->{'dom'});
#	$job || return &text('feat_evalidatecron');
#	}
#
## Make sure awstats.pl exists, and is the same as the installed version, unless
## it is a link or wrapper
#local $cgidir = &get_cgidir($d);
#local $wrapper = "$cgidir/awstats.pl";
#-r $wrapper || return &text('feat_evalidateprog', "<tt>$wrapper</tt>");
#local @cst = stat($config{'awstats'});
#local @dst = stat($wrapper);
#if (@cst && $cst[7] != $dst[7] && !-l $wrapper) {
#	open(WRAPPER, $wrapper);
#	local $sh = <WRAPPER>;
#	close(WRAPPER);
#	if ($sh !~ /^#\!\/bin\/sh/) {
#		return &text('feat_evalidatever', "<tt>$config{'awstats'}</tt>", "<tt>$cgidir/awstats.pl</tt>");
#		}
#	}
#
return undef;
}

## get_cgidir(&domain)
#sub get_cgidir
#{
#local $cgidir = $config{'copyto'} ?
#			"$_[0]->{'home'}/$config{'copyto'}" :
#			&virtual_server::cgi_bin_dir($_[0]);
#return $cgidir;
#}
#
#sub get_htmldir
#{
#return &virtual_server::public_html_dir($_[0]);
#}
#
## template_input(&template)
## Returns HTML for editing per-template options for this plugin
#sub template_input
#{
#local ($tmpl) = @_;
#local $v = $tmpl->{$module_name."passwd"};
#$v = 1 if (!defined($v) && $tmpl->{'default'});
#return &ui_table_row($text{'tmpl_passwd'},
#	&ui_radio($input_name."_passwd", $v,
#		  [ $tmpl->{'default'} ? ( ) : ( [ '', $text{'default'} ] ),
#		    [ 1, $text{'yes'} ],
#		    [ 0, $text{'no'} ] ]));
#}
#
## template_parse(&template, &in)
## Updates the given template object by parsing the inputs generated by
## template_input. All template fields must start with the module name.
#sub template_parse
#{
#local ($tmpl, $in) = @_;
#$tmpl->{$module_name.'passwd'} = $in->{$input_name.'_passwd'};
#}
#
1;

