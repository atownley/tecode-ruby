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
    end

    @junk_paths = junk_paths
    @zipfile = Zip::ZipFile.new(zipfile, create)
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

  def close
    @zipfile.close
  end
end
