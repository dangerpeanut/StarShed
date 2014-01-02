#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: starshed.pl
#
#        USAGE: ./starshed.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: dangerpeanut (na), dangerpeanut.net@gmail.com
# ORGANIZATION: DangerPeanut.net
#      VERSION: 1.0
#      CREATED: 12/14/13 22:27:38
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;
use Curses::UI;
use Getopt::Long;
use File::Slurp;
use File::Find;
use Archive::Extract;
use Cwd 'abs_path';
use feature qw/say/;

# Since the curses UI overrides standard output,  STDERR is re-established to be directed to a file.

close STDERR;

(my $errorlog = abs_path($0)) =~ s/$0/err.log/;

open STDERR, '>', $errorlog;

my (@rawassets, %config, $mod_win, %mods, @modvals, $debug, %w, %state, %modstate, %assets, @assetvals);

my $ui = new Curses::UI( -color_support => 1);

GetOptions ("debug" => \$debug);

###############
### Windows ###
###############

my $banner = <<'BANNER';
 _____ _             _____ _              _
/  ___| |           /  ___| |            | |
\ `--.| |_ __ _ _ __\ `--.| |__   ___  __| |
 `--. \ __/ _` | '__|`--. \ '_ \ / _ \/ _` |
/\__/ / || (_| | |  /\__/ / | | |  __/ (_| |
\____/ \__\__,_|_|  \____/|_| |_|\___|\__,_|

___  ___          _     _            ___  ___
|  \/  |         | |   | |           |  \/  |
| .  . | ___   __| | __| | ___ _ __  | .  . | __ _ _ __   __ _  __ _  ___ _ __
| |\/| |/ _ \ / _` |/ _` |/ _ \ '__| | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '__|
| |  | | (_) | (_| | (_| |  __/ |    | |  | | (_| | | | | (_| | (_| |  __/ |
\_|  |_/\___/ \__,_|\__,_|\___|_|    \_|  |_/\__,_|_| |_|\__,_|\__, |\___|_|
                                                                __/ |
                                                               |___/
----------------------------------------------------------------------------------------------------

You are running StarShed Modder Manager. You have made a terrible mistake.

Hit Ctrl-Q to back out now. Time is running out fast.

But if you want to do some damage, press Ctrl-F to get to the menu. It's up there somewhere.

Use TAB to switch to different parts of a window. RIGHT will select stuff too. That doesn't mean
enter won't select stuff.

----------------------------------------------------------------------------------------------------

Copyright (c) 2014, DangerPeanut
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted
provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions
and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions
and the following disclaimer in the documentation and/or other materials provided with the 
distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS 
OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING 
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
BANNER

# Defining the windows available in the program and their directives

my %screens = (
	'1' => 'Welcome', 
	'2' => 'Mod List', 
	'3' => 'Manage Mod', 
	'4' => 'Create Mod', 
	'5' => 'Asset List', 
	'6' => 'Asset Edit', 

);

my @screens = sort {$a<=>$b} keys %screens;

my %args = (
    -border       => 1,  
    -titlereverse => 0,  
    -padtop       => 2,  
    -padbottom    => 3,  
    -ipad         => 1, 
);

while (my ($nr,  $title) = each %screens)
{
	    my $id = "window_$nr";
	    $w{$nr} = $ui->add(
	        $id,  'Window',  
	        -title => "$title ($nr/" . @screens . ")", 
	        %args
	    );
};

# Where we define the actions that can be performed on a selected mod.

my %modopts = (
		1 => 'Push information changes', 
		2 => 'Trim empty folders', 
		3 => 'Import asset directory tree', 
		4 => 'Zip mod', 
		5 => 'Export .modinfo file', 
		6 => 'Export readme file', 
);

my @modoptvals = keys %modopts;

### Banner ###

$w{1}->add(
	'undef', 'Label',
	-text => $banner, 

);

### Mod List ###

$w{2}->add(
	'undef', 'Listbox', 
	-values => \@modvals, 
	-labels => \%mods,
	-onchange => \&modlist_onselect, 
);

### Mod Manager ###

$w{3}->add(
    undef,  'Label', 
    -text => "modname = The internal name of the mod. Spaces are bad.\n" .
			"desc = One line summary or tagline for your mod.\n" . 
			"PrettyName = The pretty name for your mod that you want people to see.\n" . 
			"longdesc = The long description of your mod." 
);

# Text edit fields are defined for each window on the same screen. Each widget updates the text in the other when it gains focus.

$w{3}->add(
	'modname', 'TextEditor', 
	-title => 'Internal Mod Name( NO SPACES )', -singleline => 1, -maxlength => 24, 
	-y => 5, -height => 3,  -width => 66, -border => 1,
	-onfocus => sub{
		my $self = shift;
		$self->text($modstate{'modname'});
		update_text_fields($self);
	}, 
	-onchange => sub{
		my $self = shift;
		$modstate{'modname'} = $self->get;
	}, 
);

$w{3}->add(
	'prettyname', 'TextEditor', 
	-title => 'Pretty mod name for your retarded marketing department', -singleline => 1, -maxlength => 24, 
	-y => 8, -height => 3, -width => 66, -border => 1,
	-onfocus => sub{
		my $self = shift;
		$self->text($modstate{'prettyname'});
		update_text_fields($self);
	}, 
	-onchange => sub{
		my $self = shift;
		$modstate{'prettyname'} = $self->get;
	}, 
);

$w{3}->add(
	'desc', 'TextEditor', 
	-title => 'Short Description or tagline', -singleline => 1, -maxlength => 64, 
	-y => 11,  -height => 3, -width => 66, -border => 1,
	-onfocus => sub{
		my $self = shift;
		$self->text($modstate{'desc'});
		update_text_fields($self);
	}, 
	-onchange => sub{
		my $self = shift;
		$modstate{'desc'} = $self->get;
	}, 
);

$w{3}->add(
	'longdesc', 'TextEditor', 
	-title => 'Long mod description', -wrapping => 1, -vscrollbar => 1,  
	-y => 14,   -height => 14, -width => 100, -border => 1,
	-onfocus => sub{
		my $self = shift;
		$self->text($modstate{'longdesc'});
		update_text_fields($self);
	}, 
	-onchange => sub{
		my $self = shift;
		$modstate{'longdesc'} = $self->get;
	}, 


);

$w{3}->add(
	'notes', 'TextEditor', 
	-title => 'Notes or special information before the long description', -wrapping => 1, -vscrollbar => 1, 
	-y => 28,   -height => 14, -width => 100, -border => 1,
	-onfocus => sub{
		my $self = shift;
		$self->text($modstate{'notes'});
		update_text_fields($self);
	}, 
	-onchange => sub{
		my $self = shift;
		$modstate{'notes'} = $self->get;
	}, 


);

$w{3}->add(
	'instructions', 'TextEditor', 
	-title => 'Readme Instructions', -wrapping => 1, -vscrollbar => 1, 
	-y => 42,   -height => 14, -width => 100, -border => 1,
	-onfocus => sub{
		my $self = shift;
		$self->text($modstate{'instructions'});
		update_text_fields($self);
	}, 
	-onchange => sub{
		my $self = shift;
		$modstate{'instructions'} = $self->get;
	}, 


);

$w{3}->add(
	'legal', 'TextEditor', 
	-title => 'Legal Information ( copyright )', -wrapping => 1, -vscrollbar => 1, 
	-y => 56,   -height => 14, -width => 100, -border => 1,
	-onfocus => sub{
		my $self = shift;
		$self->text($modstate{'legal'});
		update_text_fields($self);
	}, 
	-onchange => sub{
		my $self = shift;
		$modstate{'legal'} = $self->get;
	}, 


);


$w{3}->add(
	'url', 'TextEditor', 
	-title => 'The URL for your mod', -maxlength => 196, -wrapping => 1, 
	-y => 70,   -height => 3, -width => 100, -border => 1,
	-onfocus => sub{
		my $self = shift;
		$self->text($modstate{'url'});
		update_text_fields($self);
	}, 
	-onchange => sub{
		my $self = shift;
		$modstate{'url'} = $self->get;
	}, 


);

$w{3}->add(
	'version', 'TextEditor', 
	-title => 'The version of your mod', -maxlength => 10, -wrapping => 1, 
	-y => 73,   -height => 3, -width => 100, -border => 1,
	-onfocus => sub{
		my $self = shift;
		$self->text($modstate{'version'});
		update_text_fields($self);
	}, 
	-onchange => sub{
		my $self = shift;
		$modstate{'version'} = $self->get;
	}, 


);

# The widget that allows you to choose the actions to perform on the selected mod.

$w{3}->add(
	'modoptions', 'Listbox', -radio => 1, 
	-y => 76, -border => 1, 
	-title => 'Options', 
	-values => \@modoptvals, 
	-labels => \%modopts,
	-onchange => \&modoptions_select,
	-onFocus => sub{
		my $self = shift;
		$self->clear_selection;
		update_text_fields($self);
	}, 
);

### Mod Creator ###

$w{4}->add(
	'createmodname', 'TextEditor', 
	-title => 'Foldername for your new mod ( NO SPACES )', -singleline => 1, -maxlength => 24, 
	-y => 5, -height => 3,  -width => 66, -border => 1, -text => '', 
);

$w{4}->add(
	'modoptions', 'Listbox', -radio => 1, 
	-y => 8, -border => 1, 
	-title => 'Options', 
	-values => [ 1 ], 
	-labels => { 1 => 'Create Mod'}, 
	-onchange => sub{
		my $self = shift;
		my $txcreatemodname = $self->parent->getobj('createmodname');
		my $text = $txcreatemodname->get;
		$txcreatemodname->text('');
		if ($text =~ /\w/){
			create_mod($text, 'true');
		}
		$w{4}->focus;
	},
);

### Asset List ###

$w{5}->add(
	'undef', 'Listbox', 
	-values => \@assetvals, 
	-labels => \%assets,
#	-onchange => \&assetlist_onselect, 
);

### Asset Editing ###

$w{6}->add(
	'asset_editor', 'TextEditor',
	'title' => 'Asset Editor',
	-height => 10, -width => 100, -border => 1, -text => $modstate{'asset_content'}, 


):

#############
### Menus ###
#############

my $file_menu = [
    { -label => 'Quit program',        -value => sub {exit(0)}        }, 
]; 

my $assets_menu = [
    { -label => 'Asset Selection',       -value   => sub{$w{5}->focus}   }, 
    { -label => 'Edit Asset',		     -value   => sub{$w{6}->focus}   }, 
];

my $mods_menu = [
    { -label => 'Edit Selected Mod',       -value   => sub{$w{3}->focus}   }, 
    { -label => 'Mods List',       -value   => sub{$w{2}->focus}   }, 
    { -label => '---------',       -value   => sub{}}, 
    { -label => 'Create New...',       -value   => sub{$w{4}->focus}   }, 
    { -label => 'Pack All Mods',       -value   =>  \&pack_all_mods  }, 
];

my $menu = [
    { -label => 'File',                -submenu => $file_menu         }, 
    { -label => 'Modules',         -submenu => $mods_menu     }, 
    { -label => 'Assets',         -submenu => $assets_menu     }, 
];

$ui->add(
	'menu', 'Menubar', 
	-menu => $menu,
);

#################
### Functions ###
#################

# This searched the modfolder location for new folders and assumes each one contains a mod. It is then compiled into a list. This allows for the list of mods to be rebuilt during runtime.

sub compile_modmenu{

	undef %mods;

	undef @modvals;

	my $count = 1;

	opendir(my $dh, "$config{'modsdir'}") || die "Could not open file $config{'modsdir'}: $!";

	while (readdir $dh){

		next unless ( -d  "$config{'modsdir'}/$_" and $_ ne '.' and $_ ne '..' );

		print STDERR $_ . "\n" if $debug;

		$mods{$count} = $_;

		$count+=1;

	}
		@modvals = keys %mods;

	closedir $dh;

	if ($debug) {for my $mod (@modvals){
	
		print $mod . "\n";

	}}

}

sub compile_assetlist{

	my $mod = shift;

	undef %assets;

	undef @assetvals;

	my $count = 1;

	find(\&asset_search, get_mod_dir($mod));

	for my $asset (@rawassets){

		$assets{$count} = $asset;

		$count+=1;

	}

	@assetvals = keys %assets;

	undef @rawassets;
}

sub asset_search{

	if ( -f $File::Find::name and
		$File::Find::name !~ /(README.txt|modinfo)$/){
		push @rawassets, $File::Find::name;
	}


}

# This rebuilds the configuration of the program. This is not called during runtime currently but is used before the main interface loop starts.

sub build_config{

	undef %config;

	(my $configfile = abs_path($0)) =~ s/$0/config.dat/;

	say STDERR $configfile if $debug;

	open CONFIG,  '<', $configfile;

	while(<CONFIG>){

		my ( $key, $data ) = split /=/, $_;

		chomp $data;

		$data =~ s|/$||;

		$config{$key} = $data;
	}

	close CONFIG;

	$config{'details'} = [ "modname", "prettyname", "desc", "longdesc", "version", "url", "legal", "instructions", "notes" ];

}

# Here we load certain mod details from text files held in the modinfo folder. It loops through and assigne the file content to different hash values.

sub modstate_load{

	my $mod = shift;

	for my $detail (@{$config{'details'}}){
		$modstate{$detail} = read_file $config{'infodir'} . '/' . $mod . '.' . $detail, err_mode => 'carp';
	}

	compile_assetlist($mod);

}

# This does the opposite of the modstate_load. This takes the current information about the mod and exports it into individual text files from the modstate hash.

sub modstate_unload{

	my ( $mod, $dialog ) = @_;


	for my $detail (@{$config{'details'}}){
		write_file $config{'infodir'} . '/' . $mod . '.' . $detail, $modstate{$detail};
	}
	dialog('Modstate Unloaded', "Information for $mod has been saved.") if ($dialog eq 'true');
}

# This compiles a list of each option in the mod option widget and sets the subroutine to perform for each choice.

sub modoptions_select{

	my $self = shift;
	my $mod = $modstate{'selected'};
	my $selnum = $self->get;
	my %action = (
		1 => \&modstate_unload, 
		2 => \&trim_empty_dirs, 
		3 => \&import_asset_tree, 
		4 => \&zip_mod, 
		5 => \&write_modinfo, 
		6 => \&write_readme, 
	);

# Here is where we call the code based on the choice. We hand the function the name of the mod and 'true',  which means it should raise a message window when it completes.

	&{$action{$selnum}}($mod, 'true');

}

# The following function packages your mod into a zip file. It will delete the existing zipfile before making a new one.

sub zip_mod{
	my ( $mod, $dialog ) = @_;
	my $zipfile = $config{'builddir'} . '/' . $mod . '.' . "zip";
	my $dir = get_mod_dir($mod);

	unlink $zipfile && print STDERR "Removed $zipfile" || warn "Could no remove $zipfile: $!";

	for (keys %modstate){
		chomp $modstate{$_};
	}

	write_modinfo($mod);

	write_readme($mod);

	trim_empty_dirs($mod);

# Calls the zcript that packs the zip file. It needs to be given the location to store the zip,  the location of the mod,  and the mod to zip.

	system($config{'packscript'}, $mod, "$config{'modsdir'}", "$config{'builddir'}");

	dialog('Zip Mod', "$mod has been compressed into $zipfile") if ($dialog eq 'true');

}

# This function accepts the mod name and dialog boolean so that it can write the modinfo file based on the modstate information.

sub write_modinfo{
	my ( $mod, $dialog ) = @_;
	my $dir = get_mod_dir($mod);

# The variable that holds the JSON for the .modinfo. Valid json syntax with variables for your mod information to be interpolated.
	
	my $json = <<MODINFO;
{
  "name" : "$mod",
  "version" : "$config{'sbversion'}",
  "path" : ".",
  "metadata" : {
    "displayName" : "$modstate{'prettyname'}",
    "author" : "$config{'author'}",
    "description" : "$modstate{'desc'}",
    "support_url" : "$modstate{'url'}",
    "version" : "$modstate{'version'}"
  }
}
MODINFO

# We write the modinfo file and let the user know it is done.
	
	write_file $dir . '/' . $mod . '.' . 'modinfo', $json; 
	dialog('Modinfo', "Modinfo exported.") if ($dialog eq 'true');

}

sub write_readme{
	
	my ( $mod, $dialog ) = @_;
	my $dir = get_mod_dir($mod);

	my $readme = <<README;
############
### Info ###
############

$modstate{'prettyname'}
	$modstate{'desc'}

Made by: $config{'author'}

Email: $config{'email'}

Notes: $modstate{'notes'}

===================
=== Description ===
===================

$modstate{'longdesc'}

++++++++++++++++++++
+++ Instructions +++
++++++++++++++++++++

$modstate{'instructions'}

*************************
*** Legal Information ***
*************************

$modstate{'legal'}

------------------------

All, some, or none of this mod was manhandled by StarShed Modder Manager.
README

	write_file $dir . '/' . 'README.txt', $readme; 
	dialog('Readme', "Readme file has been exported.") if ($dialog eq 'true');

}

# Takes the mod name and dialog boolean to find empty folders in the mod directory and remove them.

sub trim_empty_dirs{
	my ( $mod, $dialog ) = @_;
	system($config{'emptydirscript'}, $mod, "$config{'modsdir'}");
	dialog('Trimmed', "No more empty folders in $mod") if ($dialog eq 'true');
}

# Unzip the directory tree for starbound assets into the mod folder.

sub import_asset_tree{
	my ( $mod, $dialog ) = @_;
	my $dir = get_mod_dir($mod) . '/';
	my $arc = Archive::Extract->new( archive => $config{'sbdirtree'});
	$arc->extract( to => $dir );
	dialog('Imported Assets', "Vanilla folder tree imported to $mod.") if ($dialog eq 'true');
}

# Accepts the name of the mod and returns the directory where the mod is stored.

sub get_mod_dir{
	my $mod = shift;
	my $folder = $config{'modsdir'} . '/' . $mod . '/';
	return $folder;
}

# When we select a mod from the mod list,  this function will load the relevant mod information into the modstate,  set the mod as selected,  and unload any existing information for another mod before it lodas a new one.

sub modlist_onselect{
	my $self = shift;
	my $selnum = $self->get;
	my $sel = $mods{$selnum};
	$sel = 'none' unless $sel;
	if ($sel ne 'none' and $sel ne $modstate{'selected'}){
		modstate_unload($modstate{'selected'}) if $modstate{'selected'};
		$state{'lastselectedmod'} = $modstate{'selected'};
		$modstate{'selected'} = $sel;
		modstate_load($sel);
	}
	$w{3}->focus;

}

# When we need a popup message to be sent to notify the user that something has been done. Accepts the messagebox title and message content.

sub dialog{
	my $title = shift;
	my $msg = shift;
	$ui->dialog(
		-title => $title, 
		-message => $msg, 
);
}


sub create_mod{
	my ($mod, $dialog) = @_;
	my $dir = get_mod_dir($mod);

	next if (-e $dir);

	mkdir $dir;

	import_asset_tree($mod);

	for my $detail (@{$config{'details'}}){

		write_file $config{'infodir'} . '/' . $mod . '.' . $detail, '';

	}

	compile_modmenu;

	dialog('Mod Creation', "The mod $mod has been created. Please select it from the mod list.") if ($dialog eq 'true');
}

# For all the mods that are detected,  it loads the information and performs the zip_mod function. Reloads the information of any selected mod before it was called.

sub pack_all_mods{

	for my $key (keys %mods){
		modstate_load($mods{$key});
		zip_mod($mods{$key});
	}
	modstate_load($modstate{'selected'}) if $modstate{'selected'};
	dialog('Mods Packed', "All mods have been zipped for distribution");

}

# This is called every time an info field in the mod editor gains focus. Pushes info from modstate into each field. This is useful if another mod is selected. Once a mod is selected,  it returns to the mod edit screen. Any of the fields may have focus when the window is brought up,  so each one needs to update all the fields if it is the one that recieves focus.

sub update_text_fields{
	my $self = shift;
		my $txmodname = $self->parent->getobj('modname');
		$txmodname->text($modstate{'modname'});
		my $txdesc = $self->parent->getobj('desc');
		$txdesc->text($modstate{'desc'});
		my $txurl = $self->parent->getobj('url');
		$txurl->text($modstate{'url'});
		my $txversion = $self->parent->getobj('version');
		$txversion->text($modstate{'version'});
		my $txlongdesc = $self->parent->getobj('longdesc');
		$txlongdesc->text($modstate{'longdesc'});
		my $txprettyname = $self->parent->getobj('prettyname');
		$txprettyname->text($modstate{'prettyname'});
		my $txlegal = $self->parent->getobj('legal');
		$txlegal->text($modstate{'legal'});
		my $txinstructions = $self->parent->getobj('instructions');
		$txinstructions->text($modstate{'instructions'});
		my $txnotes = $self->parent->getobj('notes');
		$txnotes->text($modstate{'notes'});
}

############
### Main ###
############

build_config;

compile_modmenu;

$ui->set_binding( sub{ shift()->root->focus('menu') },  "\cF" );
$ui->set_binding( sub{exit(0)} , "\cQ");

$w{1}->focus;
$ui->mainloop();
