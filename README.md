Geany for macOS
===============
Geany for macOS is a project that contains all the necessary configuration
files, themes, scripts and instructions to create the Geany app bundle and 
a dmg installer image for macOS.

Binaries
--------
The macOS binaries can be downloaded from the Geany Releases page:

<https://www.geany.org/Download/Releases>

Configuration
-------------
In addition to standard Geany configuration, the macOS bundle creates
its own configuration file under `~/.config/geany/geany_mac.conf` upon
first start. In this configuration file it is for instance possible
to override the used theme (light/dark) when autodetection based on
system macOS theme is not desired.

Files and Directories
---------------------
A brief description of the contents of the project directory:

### Directories
*	*Launcher*: A binary launcher which is used to set up environment
	variables to run Geany.
*	*Prof-Gnome*: Prof-Gnome 3.6 GTK 3 Theme with minor modifications
*	*Papirus, Papirus-Dark*: Papirus GTK 3 icon theme with lots of unneeded
	icons removed to save space.
*	*macos-icon-design*: design file for macOS Geany icon.
*	*iconbuilder.iconset*: source Geany icons for the bundle.
*	*modulesets-stable, patches*: copy of the modulesets-stable and patches 
    directory from the [gtk-osx](https://gitlab.gnome.org/GNOME/gtk-osx/)
	project containing dependency specifications. Since the upstram project 
	is sometimes in an unstable state, this allows us to make a snapshot of
	a working configuration for our build.
*	*geany_patches*: various patches fixing dependencies to enable bundling.
*	*utils*: various utility scripts.

### Configuration files
*	*Info.plist*: macOS application configuration file containing some basic
	information such as application name, version, etc. but also additional
	configuration including file types the application can open.
*	*geany.bundle*: configuration file describing the contents of the app bundle.
*	*geany.entitlements*: runtime hardening entitlements file.
*	*geany.modules*: JHBuild modules file with Geany dependencies.
*	*settings.ini*: default theme configuration file for GTK 3. 

### Scripts
*	*bundle.sh*: script creating the app bundle. 
*	*create_dmg.sh*: script calling create-dmg to create the dmg installer
	image. 
*	*notarize.sh*: script for notarizing the dmg using Apple notary service. 
*	*sign.sh*: script signing the app bundle. 

General Instructions
--------------------
For more general instructions about building and bundling macOS applications
please visit

*	<https://gitlab.gnome.org/GNOME/gtk-osx/>
*	<https://gitlab.gnome.org/GNOME/gtk-mac-bundler/>

The HOWTO below contains just the portions necessary/relevant for
building and bundling Geany.

Prerequisities
--------------
*	macOS
*	Xcode and command-line tools

Building
--------
To create the bundle, you need to first install JHBuild and GTK as described below.

1.	Create a new account for jhbuild (not necessary but this makes sure
	jhbuild does not interfere with some other command-line tools installed
	on your system).

2.	Optionally, when cross-compiling x86_64 binaries on a new ARM-based
	Apple computer, run
	```
	env /usr/bin/arch -x86_64 /bin/zsh --login
	```
	to create a `x86_64` shell. All the compilation steps below
	have to be executed in this shell.

3.	Depending on the used shell, add the following lines
	```
	export PATH=$PATH:"$HOME/.new_local/bin"
	export LC_ALL=en_US.UTF-8
	export LANG=en_US.UTF-8
	```
	either to your `.zprofile` or `.bash_profile` to make sure these variables
	are defined and restart your shell.

4.	Get `gtk-osx-setup.sh` by
	```
	curl -L -o gtk-osx-setup.sh https://gitlab.gnome.org/GNOME/gtk-osx/raw/master/gtk-osx-setup.sh
	```
	and run it:
	```
	bash gtk-osx-setup.sh
	```

5.	Add the following lines to `~/.config/jhbuildrc-custom`:
	```
	setup_sdk(target="10.13", architectures=["x86_64"])
	#setup_sdk(target="11", architectures=["arm64"])
	setup_release()  # enables optimizations
	```
	With this settings, the build creates a 64-bit Intel binary that works on
	macOS 10.13 and later. Instead of `x86_64` you can also specify
	`arm64` to produce binaries for Apple ARM processors. This only works
	when building on ARM processors - it isn't possible to compile
	ARM binaries on Intel processors.

6.	Install GTK and all of its dependencies by running the following
	command inside the `geany-osx` directory:
	```
	jhbuild bootstrap-gtk-osx && jhbuild build meta-gtk-osx-bootstrap meta-gtk-osx-gtk3
	```
	The upstream project is sometimes in an unstable state and fails to build;
	if this happens, you can use our snapshot of modulesets which was used
	to build the last release of Geany:
	```
	jhbuild bootstrap-gtk-osx && jhbuild -m "https://raw.githubusercontent.com/geany/geany-osx/master/modulesets-stable/gtk-osx.modules" build meta-gtk-osx-bootstrap meta-gtk-osx-gtk3
	```

7.	To build Geany, plugins and all of their dependencies, run one of
	the following commands inside the `geany-osx` directory  depending on
	whether to use Geany sources from the latest release tarball or current
	git master:
	* **tarball**
		```
		jhbuild -m `pwd`/geany.modules build geany-bundle-release
		```
	* **git master**
		```
		jhbuild -m `pwd`/geany.modules build geany-bundle-git
		```

Bundling
--------
1.  To build the launcher binary, run
	```
	xcodebuild ARCHS=`uname -m` -project Launcher/geany/geany.xcodeproj clean build
	```
	inside the `geany-osx` directory.

2.	Run
	```
	jhbuild shell
	```
	to start jhbuild shell. 

	*Steps 3 and 4 of this section assume you are running from within the jhbuild shell.*

3.	Inside the `geany-osx` directory run the following command to create
	the app bundle:
	```
	./bundle.sh
	```

4.	Leave jhbuild shell if it was entered in step 2 by typing `exit`.

5.	Optionally, if you have a development account at Apple and want to
	sign the resulting bundle, get the list of signing identities by
	```
	security find-identity -p codesigning
	```
	and use the whole string within apostrophes which contains
	"Developer ID Application: ..." in the following command:
	```
	export SIGN_CERTIFICATE="Developer ID Application: ..."
	```
	Then, run
	```
	./sign.sh
	```

Distribution
------------
1.	Get the `create-dmg` script from

	<https://github.com/andreyvit/create-dmg.git>

	and put it to your `$PATH`.

2.	Create the dmg installation image by calling
	```
	./create_dmg.sh
	```
	from within the `geany-osx` directory. If the `SIGN_CERTIFICATE` variable is
	defined (see above), the image gets signed by the specified certificate.

3.	Optionally, to get the image notarized by
	[Apple notary service](https://developer.apple.com/documentation/security/notarizing_your_app_before_distribution),
	run
	```
	./notarize.sh <dmg_file> <apple_id>
	```
	where `<dmg_file>` is the dmg file generated above and `<apple_id>`
	is the Apple ID used for your developer account. The script then
	prompts for an [app-specific password](https://support.apple.com/en-us/HT204397)
	generated for your Apple ID.

Maintenance
-----------
This section describes some maintenance-related activities which do not
have to be performed during normal bundle/installer creation:

*	To get the `Info.plist` file associations in sync with 
	`filetype_extensions.conf`, copy the filetype extension portion from
	`filetype_extensions.conf` to the marked place in `utils/plist_filetypes.py`
	and run the script. Copy the output of the script to the marked
	place in `Info.plist`.

*	Before the release, update the Geany version and copyright years inside
	`Info.plist` and `create_dmg.sh`. Also update the `-release` targets in
	`geany.modules` file to point to the new release. Dependencies inside
	`geany.modules` can also be updated to newer versions.

*	Copy `modulesets-stable` from [gtk-osx](https://gitlab.gnome.org/GNOME/gtk-osx/)
	into this project to get the latest dependencies (if it builds) and
	possibly modify it (if something isn't working).

*	To make sure nothing is left from the previous build when making a
	new release, run
	```
	rm -rf .new_local .local Source gtk .cache/jhbuild
	```

---

Jiri Techet, 2025
