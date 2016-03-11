#!/usr/bin/env python


# Insert the contents of the [Extensions] section from filetype_extensions.conf below
filetype_extensions = '''
Abaqus=*.inp;
Abc=*.abc;*.abp;
ActionScript=*.as;
Ada=*.adb;*.ads;
Asciidoc=*.asciidoc;*.adoc;
ASM=*.asm;*.asm51;*.a51;
Batch=*.bat;*.cmd;*.nt;
CAML=*.ml;*.mli;
C=*.c;*.h;*.xpm;
C++=*.cpp;*.cxx;*.c++;*.cc;*.h;*.hpp;*.hxx;*.h++;*.hh;*.C;*.H;
Clojure=*.clj;*.cljs;*.cljc;
CUDA=*.cu;*.cuh;*.h;
C#=*.cs;
CMake=CMakeLists.txt;*.cmake;*.ctest;
COBOL=*.cob;*.cpy;*.cbl;*.cobol;
CoffeeScript=*.coffee;Cakefile;*.Cakefile;*.coffee.erb;*.iced;*.iced.erb;
Conf=*.conf;*.ini;config;*rc;*.cfg;*.desktop;*.properties;
CSS=*.css;
Cython=*.pyx;*.pxd;*.pxi;
D=*.d;*.di;
Diff=*.diff;*.patch;*.rej;
Docbook=*.docbook;
Erlang=*.erl;*.hrl;
F77=*.f;*.for;*.ftn;*.f77;*.F;*.FOR;*.FTN;*.fpp;*.FPP;
Ferite=*.fe;
Forth=*.fs;*.fth;
Fortran=*.f90;*.f95;*.f03;*.f08;*.F90;*.F95;*.F03;*.F08;
FreeBasic=*.bas;*.bi;*.vbs;
Genie=*.gs;
GLSL=*.glsl;*.frag;*.vert;
Go=*.go;
Graphviz=*.gv;*.dot;
Haskell=*.hs;*.lhs;*.hs-boot;*.lhs-boot;
Haxe=*.hx;
HTML=*.htm;*.html;*.shtml;*.hta;*.htd;*.htt;*.cfm;*.tpl;
Java=*.java;*.jsp;
Javascript=*.js;
JSON=*.json;
LaTeX=*.tex;*.sty;*.idx;*.ltx;*.latex;*.aux;*.bib;
Lisp=*.lisp;
Lua=*.lua;
Make=*.mak;*.mk;GNUmakefile;makefile;Makefile;makefile.*;Makefile.*;
Markdown=*.mdml;*.markdown;*.md;*.mkd;*.mkdn;*.mdwn;*.mdown;*.mdtxt;*.mdtext;
Matlab/Octave=*.m;
NSIS=*.nsi;*.nsh;
Objective-C=*.m;*.mm;*.h;
Pascal=*.pas;*.pp;*.inc;*.dpr;*.dpk;
Perl=*.pl;*.perl;*.pm;*.agi;*.pod;
PHP=*.php;*.php3;*.php4;*.php5;*.phtml;
Po=*.po;*.pot;
Python=*.py;*.pyw;SConstruct;SConscript;wscript;
PowerShell=*.ps1;*.psm1;
reStructuredText=*.rest;*.reST;*.rst;
R=*.R;*.r;
Rust=*.rs;
Ruby=*.rb;*.rhtml;*.ruby;*.gemspec;Gemfile;rakefile;Rakefile;
Scala=*.scala;*.scl;
Sh=*.sh;configure;configure.in;configure.in.in;configure.ac;*.ksh;*.mksh;*.zsh;*.ash;*.bash;.bashrc;bash.bashrc;.bash_*;bash_*;*.m4;PKGBUILD;*profile;
SQL=*.sql;
Tcl=*.tcl;*.tk;*.wish;
Txt2tags=*.t2t;
Vala=*.vala;*.vapi;
Verilog=*.v;
VHDL=*.vhd;*.vhdl;
XML=*.xml;*.sgml;*.xsl;*.xslt;*.xsd;*.xhtml;*.xul;*.dtd;*.xtpl;*.mml;*.mathml;
YAML=*.yaml;*.yml;
Zephir=*.zep;
'''


def print_plist_entry(lang, ext_set):
	padding = '\t\t'
	print padding + '<dict>'
	padding += '\t'
	
	print padding + '<key>CFBundleTypeName</key>'
	print padding + '<string>' + lang + ' Source</string>'

	print padding + '<key>CFBundleTypeExtensions</key>'
	print padding + '<array>'
	padding += '\t'
	for ext in sorted(ext_set):
		print padding + '<string>' + ext + '</string>'
	padding = padding[:-1]
	print padding + '</array>'

	print padding + '<key>CFBundleTypeIconFile</key>'
	print padding + '<string>Geany.icns</string>'
	print padding + '<key>CFBundleTypeRole</key>'
	print padding + '<string>Editor</string>'
	print padding + '<key>LSHandlerRank</key>'
	print padding + '<string>Alternate</string>'

	padding = padding[:-1]
	print padding + '</dict>'


lines = filetype_extensions.split('\n')
for line in lines:
	if line.strip() == '':
		continue
	lang, types = line.split('=')
	type_list = types.split(';')
	ext_set = set()
	for ftype in type_list:
		ftype = ftype.strip()
		if ftype == '':
			continue
		elif ftype.startswith('*.'):  # interested only in extensions
			ext_set.add(ftype[2:])
#		else:
#			print 'Ignoring:', ftype
	if lang == 'Sh':
		ext_set = ext_set.union(set(['in', 'am', 'ac']))  # these are not defined in the list in the form *.extension
		
	if ext_set:
#		print ext_set
		print_plist_entry(lang, ext_set)
