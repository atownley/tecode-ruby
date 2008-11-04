#--
######################################################################
#
# Copyright 2005-2008, Andrew S. Townley
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
# File:     properties.rb
# Author:   Andrew S. Townley
# Created:  Fri Dec  2 19:51:05 GMT 2005
#
######################################################################
#++

module TECode
module IO

  # This class defines a processor/reader for Java-style
  # properties files

  class PropertiesFile
    
    # The constructor takes the name of the file to load use
    # to provide string resources

    def initialize(file)
      @resources = {}
      File.open(file, "r") do |file|
        file.each_line { |line| parse_line(@resources, line.chomp) }
      end
    end

    # This method returns the resource string

    def get_string(key)
      @resources[key]
    end

    def keys
      @resources.keys
    end

  private
    def parse_line(map, line)
      # skip comments
      if line =~ /^#/
        return
      end

      i = line.index('=')
      key = line[0..i-1].chomp.strip
      val = line[i+1..line.length].chomp.strip
      map[key] = val
    end
  end
end
end
