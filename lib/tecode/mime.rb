#--
######################################################################
#
# Copyright (c) 2005-2008, Andrew S. Townley
# All rights reserved.
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
# File:        mime.rb
# Author:      Andrew S. Townley
# Created:     Wed Nov  5 08:45:53 GMT 2008
#
######################################################################
#++

# this depends on the Ruby MIME::Types library from
# http://mime-types.rubyforge.org
require 'rubygems'
require 'mime/types'

if __FILE__ != $0
  # automatically generated from the mime_types.txt file by
  # this script.  Any updates should be placed in the
  # mime_types.txt file
  
  require 'tecode/mime_types'
end

module TECode

# This module defines constants for the registered IANA Mime
# types obtained from http://www.iana.org/assignments/media-types
# on 2008-11-05

module MimeType
  # Add some application-specific ones
  module Application
    X_RUBY_OBJECT     = MIME::Types["application/x-ruby-object"]
  end
end

end

if __FILE__ == $0
  require './time'

  @module = nil
  
  def mime_helper(type)
    group = File.dirname(type)
    if @module != group
      if !@module.nil?
        puts "end\n\n"
      end
      @module = group
      puts "module #{@module.capitalize}"
    end
    const = File.basename(type).gsub(/[-.+]/, "_").upcase
    if const =~ /^\d/
      const = "_#{const}"
    end
    puts "    #{const} = MIME::Types[\"#{type}\"][0]"
  end

  puts "# Automatically generated from mime_types.txt on #{Time.tstamp}"
  puts "module TECode\nmodule MimeType"

  loop do
    line = gets or break
    next if (line.strip!.nil? || line == "")
    mime_helper(line)
  end
  puts "end\nend\nend"
end
