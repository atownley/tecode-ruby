#--
######################################################################
#
# Copyright 2005-2016, Andrew S. Townley
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
# File:     ini.rb
# Author:   Andrew S. Townley
# Created:  Sat Dec  3 12:47:22 GMT 2005
#
######################################################################
#++

module TECode
module IO

  # This class is used to parse INI files and expose the
  # information in them in a sensible manner.

  class IniFile
    
    # The constructor takes the name of the file to load use
    # to provide string resources

    def initialize(file)
      @sections = {}
      @current = {}
      File.open(file, "r") do |file|
        file.each_line { |line| parse_line(@sections, line.chomp) }
      end
    end

    def [](key)
      @sections[key]
    end

    def []=(key, value)
      @sections[key] = value
    end

  private
    def parse_line(map, line)
      # skip comments and empty lines
      if line =~ /^#/ || line =~ /^;/ || line =~ /^[\s]*$/
        return
      end
    
      # is it a section
      if line =~ /^[\s]*\[.*\][\s]*$/
        sname = $&[1..-2].strip
        @sections[sname] = {}
        @current = @sections[sname]
        return
      end

      # it's a value
      i = line.index('=')
      key = line[0..i-1].chomp.strip
      val = line[i+1..line.length].chomp.strip
      @current[key] = val
    end
  end
end
end
