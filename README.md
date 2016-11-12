TECode the Ruby Version
=======================

This repository is now home to the official ruby version of the TECode
library originally developed in Java, C# and Python and hosted on
Sourceforge from 2003 until all this code was migrated to GitHub in
2016.

Utilities of Note
-----------------

distbundle - this utility is used to package a set of files for
distribution as a zip file.

jspkg - this utility is based on distbundle and allows the packaging
of javascript and css files, optionally minimized.

Command-line Interfaces
-----------------------

The original command line argument parsing developed in the Java
version has been implemented, more-or-less, in Ruby, and is in heavy,
daily production use in a number of projects.  The Ruby version isn't
quite as sophisticated as the Java version, but it does the job.

Examples on how this is done are provided in the sample/feather.rb
file.

Configuration Files
-------------------

Ruby implementations for managing INI and Java Properties files are
provided in the tecode/io directory.

Table Models
------------

A set of object-based table models, roughly based on the Java
TableModel API is provided in the tecode/table directory.  These were
used initially during the development of some GTK+/GNOME applications
on Linux years ago, but they are toolkit independent.

Thread/Task Management
----------------------

There are some simple classes for managing threads, events and tasks.
Again, these were originally developed for the GTK+/GNOME desktop
appliations, but they are generic and have no toolkit dependencies.

XML Manipulation/Mapping
------------------------

The libary also includes some classes for more easily mapping XML into
in a pretty flexibile way.  It was originally inspired by the
[HappyMapper](https://github.com/jnunemaker/happymapper) library, but
I needed better support for namespaces and more flexible mappings
based on XPath expressions.
