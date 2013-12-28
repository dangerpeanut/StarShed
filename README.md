StarShed
========

A Starbound mod manager for modders

## Contents

* README
	This file

* starshed.pl  
	This is the perl program that you run. Non developers should not change this file.

* config.dat.sample  
	Where the program stores global configuration information. You will configure storage directories and some paths here.

* scripts/

- cleanempties.sh  
	This is a small script that is called by the program to clean empty folders from a mod's folder.

- packmod.sh  
	Another small script called by the program that packages your mod into one zip file.

* dirtree.zip  
	A copy of the starbound directory tree( As of Offended Koala ).

## Requirements

The software requirements are simple, but should not be ignored.

* Perl 5.10 or higher ( developed on 5.14.4 )
* Bash  
	This is included in many, if not all linux distributions. OSX should have this as the default shell too. BSD variants will need this to be installed.
* The following perl modules: Curses::UI, Getopt::Long, File::Slurp, Archive::Extract.

### Meeting the requirements

As implied by these requirements, a unix-like operating system is required. Apple OSX, most linux distributions, and any BSD variant (FreeBSD, OpenBSD, NetBSD) all meet these criteria. You may be able to get this to function on Windows with cygwin ( http://www.cygwin.com/ ).

If you don't know how to install perl modules, then you should skip to the section for CPAN on this page: http://www.perlmonks.org/?node_id=128077

## Instructions

### Paths

This config.dat will need paths. When we use paths, we do not use relative paths. We need to use absolute paths that start from root.

>EG:

		Relative path: ~/my_mods/some/path/to/foldername  
		Relative path: my_mods/some/path/to/foldername  
		Absolute path: /usr/home/username/my_mods/some/path/to/foldername  
		Absolute path: /usr/home/username/my_mods/some/path/to/filename  

### Mod Storage

Every mod should be in its own folder in the mod storage folder. Under this folder should be the normal asset folders. There should not be an 'assets' folder in the folder where your mod resides.

>EG:

	/usr/home/username/my_mods/examplemod/ -  
 	        				|- items  
						|- recipes  
						|- objects  
						\- etc  

Extract to the folder you wish to run the program from.

## Config File

Before you can use this program, you will need to configure it. Make a copy of the config.dat.sample file and make it 'config.dat'. This file is _required_ to be in the same folder as the main modderman.pl program.

There are a number of values here that you need to fill in. Every entry should be as follows on its own line:

>label=value

Here is the run down of each label.

- sbversion  
	The version of Starbound that your mods support.
	
- author  
	Your name or moniker.
		
- email   
	Your contact email address if you wish.
		
- modsdir  
	The path to the folder where your mods will be stored.
		
- infodir  
	This folder will store information for your mod. This includes the mod name, description, readme instructions, legal notices(copyright), modinfo data, etc. It will not be stored among your mod's assets, so this is where it is stored. It is read and formatted for your mod when it is packaged.
		
- starboundassets **UNUSED**  
	If you can, include the path to your starbound 'assets' folder. This is not used now, but will be in the future.
		
- builddir  
	This is where your zipped mods will be stored. Once you package your mod, it will be found in this folder.
	
- sbdirtree DEFAULT: dirtree.zip   
	Expected to be a file path to a zip archive. The zip file should contain a directory tree of the starbound assets folder. The zip dirtree.zip serves this function and is distributed with the program. This zip holds no assets.
		
- binbash  
	The path to your bash binary. On many linux systems, this is /bin/bash, but that is not always the case. You should put the path to bash here. Try running 'which bash'.
		
- packscript  
	This is the path to the packsmod.sh script that came bundled with this program. You can move the script if you want, but the configuration needs to know where the script will reside.
		
- emptydirscript  
	Another path for a script packaged with the mod.

Once all of these labels have a value, one more thing is needed before you can use the program. The bundled scripts need to be made executable. From a terminal, you can accomplish this from the included scripts folder by doing 'chmod +x \*.sh'.

That should be all. Now you can go back to where you put the program. Run 'perl modderman.pl'.

## The Program

You should be greeted with a user interface in your terminal. If your terminal is too small, resize it and the interface should appear. If it does *nothing*, then something has gone wrong. Please see the TROUBLESHOOTING section.

As the onscreen text says, you can quit anytime with CTRL-Q or using the quit option in the file menu. You can access the menu by pressing CTRL-F.

Under the Modules menu, the meat of the program resides. You can repack all mods, return to the mod manage screen, select a mod for individual change, or create a new mod here.

### Mod List

	This screen will list all the folders that reside in your mods folder. Select one to begin managing it.

### Managing Mods

If you have selected a mod from the mod list, then you will appear at a new screen. You should see many text fields for your mod appear. Below these fields is a menu for performing actions on your mod.
	
You can go to the next field by keying TAB. You can only go one way I'm afraid, so if you want to go up, go down until it loops.
	
When you are done filling out the information fields, you can use the options below. These options are as follows.

	- Zip Mod  
		This will remove all empty folders, export the mod info/readme/modinfo files, and zip your mod.
		
	- Import asset directory tree  
		Imports the vanilla asset folder tree from dirtree.zip into your mod's folder.
		
	- Push information changes  
		Exports all text field data into storage files that reside in your infodir folder.
		
	- Export .modinfo file  
		Exports the .modinfo file for your mod based on information in the text fields.
		
	- Export readme file  
		Exports the README.txt file for your mod.
		
	- Trim Empty Folders  
		Removes any empty folders within your mod's folder.

## Troubleshooting

There will be bugs. All programs have bugs. There are three different things that can go wrong.

	* Running the program does nothing. It stays in the shell with no output.
		
	* Running the program produces error messages.  
		If this happens to you, make sure you installed all the required perl modules.
		
	* While doing stuff in the program, you are returned to the shell without quitting.

In the cases where no errors appear, then you must look at the error log to see what went wrong. The program shoves everything from STDERR into err.log. It resides in the same folder as the program.
	
If I can't see the error, then I don't know what to fix.
