#--
######################################################################
#
# Copyright 2010, Andrew S. Townley
#
# Permission to use, copy, modify, and disribute this software for
# any purpose with or without fee is hereby granted, provided that
# the above copyright notices and this permission notice appear in
# all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHORS DISCLAIM ALL
# WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS.  IN NO EVENT SHALL THE
# AUTHORS BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT OR
# CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
# NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
# CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# File:     zip.rb
# Author:   Andrew S. Townley
# Created:  Fri  3 Sep 2010 01:36:08 IST
#
######################################################################
#++

require 'fileutils'
require 'zip/zip'
require 'zip/zipfilesystem'

# This class provides an API adapter around the rubyzip
# ZipFileSystem API that makes it easier to do the simple
# stuff like zipping a directory.

class TECode::ZipFile
  def self.open(zipfile, mode = "r+", junk_paths = false, &block)
    zipfile = self.new(zipfile, mode, junk_paths)
    if block
      block.call(zipfile)
      zipfile.close
      return
    end
    zipfile
  end

  def initialize(zipfile, mode = "r+", junk_paths = false)
    # FIXME:  need to prohibit modifications in "r" mode?
    create = 0
    case(mode)
    when /^w/
      if File.exist? zipfile
        File.delete(zipfile)
        create = 1
      end
    when /^a/
      create = 1
    when /^r$/
      if !File.exist? zipfile
        raise ArgumentError, "file '#{zipfile}' not found."
      end
    end

    @junk_paths = junk_paths
    path = File.expand_path(zipfile)
    @zipfile = Zip::ZipFile.new(path, create)
  end

  def <<(path)
    add(path)
  end

  def add(path)
#    puts "Adding '#{path}'..."
    if path =~ /^\.[^\.]/
      path = File.basename(path)
    end

    if "." == path
      Dir.glob("*").each { |f| add(f) }
    elsif path =~ /^\.\./
      # we've a relative path, so add the contents of that
      # path
      Dir.chdir(path)
#      puts "Dir.pwd: #{Dir.pwd}"
      Dir.glob("*").each { |f| add(f) }
    elsif File.directory? path
      if !@junk_paths
        dir = File.dirname(path)
        if "." == dir
          dir = path
#        elsif dir =~ /^\.[^\.]/
#          dir = File.basename(dir)
        end
#        puts "mkdir #{dir}"
        @zipfile.dir.mkdir(dir) if !@zipfile.file.exists? dir
      end
      Dir.glob(File.join(path, "*")).each { |f| add(f) }
    else
      entry = @junk_paths ? File.basename(path) : path
      @zipfile.add(entry, path)
    end
    self
  end

  # This method will extract the contents of the zip file to
  # the specified location.

  def extract_to(path, overwrite = true)
    path = File.expand_path(path)
    if !File.exists? path
      Dir.mkdir(path)
    end
    Dir.chdir(path)
    extract overwrite
  end

  # This method will extract the contents of the zip file to
  # the current directory

  def extract(overwrite = true)
    root = Dir.getwd
#    puts "root: #{root}"
    @zipfile.each do |entry|
      targ = File.join(root, entry.name)
#      puts "targ: #{targ}"
      targdir = File.dirname(targ)
      if !File.exist? targdir
#        puts "Making directory #{targdir}"
        FileUtils.mkdir_p(targdir)
      end
      
#      puts "Extracting file #{targ}"
      entry.extract(targ) { overwrite }
    end
  end

  def close
    @zipfile.close
  end
end
