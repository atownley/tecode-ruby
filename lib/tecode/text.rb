#--
######################################################################
#
# Copyright (c) 2008, Andrew S. Townley
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
# File:        text.rb
# Author:      Andrew S. Townley
# Created:     Wed Nov  5 20:14:53 GMT 2008
#
######################################################################
#++

$KCODE='u'
require 'jcode'

# From http://blog.evanweaver.com/articles/2006/09/03/smart-plaintext-wrapping/
# with a few tweaks...

class String

  def wrap(width, hanging_indent = 0, magic_lists = false, &block)
    lines = self.split(/\n/)

    lines.collect! do |line|

      if magic_lists 
        line =~ /^([\s\-\d\.\:]*\s)/
      else 
        line =~ /^([\s]*\s)/
      end

      indent = $1.length + hanging_indent rescue hanging_indent

      buffer = ""
      first = true

      while line.length > 0
        first ? (i, first = 0, false) : i = indent              
        pos = width - i

        if line.length > pos and line[0..pos] =~ /^(.+)\s/
          subline = $1
        else 
          subline = line[0..pos]
        end
        lbuf = " " * i + subline + "\n"
        lbuf = block.call(lbuf) if block
        buffer += lbuf
        line.tail!(subline.length - 1)
      end
      buffer[0..-2]
    end

    lines.join("\n")

  end

  def tail!(pos)
    self[0..pos] = ""
    strip!
  end

end

module TECode
module Text
  DIGIT     = %r{[-+]?\d+(?:\.?\d+)?}
  HEXDIGIT  = %r{[-+]?0x[a-fA-F\d][a-fA-F\d]*}
  QLITERAL  = %r{(?:"(?:[^"\\]|\\.)*")|'(?:[^'\\]|\\.)*'}
  
  # This function should be used whenever user-input strings
  # need to be parsed into the corresponding runtime value.

  def self.parse_string(str)
    return str if !str.is_a? String

    val = str
    case val 
      when /^#{HEXDIGIT}$/ then val = val.hex
      when /^[-+]?0\d+$/ then val = val.oct
      when /^[-+]?\d+$/ then val = val.to_i
      when /^#{DIGIT}$/ then val = val.to_f
      when /^#{DIGIT}%$/ then val = val.to_f / 100
      when /^:([^\s]*)$/
        val = $1.gsub(/\s+/, "-")
        if !val.nil? && "" != val
          val = val.to_sym
        else
          val = nil
        end
      when /^\\:/ then val = $1.gsub(/^\\:/, "")
      when /^true$/i then val = true
      when /^false$/i then val = false
    end
    val
  end

  # This function performs extremely basic type conversion.
  # It can probably be enhanced to cover more comprehensive
  # scenarios.

  def Text.convert(klass, val)
#    puts "klass: #{klass} vs. #{val.class}"
    return val if (val.nil? || val.is_a?(klass) || klass == NilClass) 

    if (klass != val.class) && (val.is_a? String)
      dest = parse_string(val)
      if dest.class != klass
        if dest.class == FalseClass && klass == TrueClass
          return dest
        elsif dest.class == TrueClass && klass == FalseClass
          return dest
        elsif val == "1"
          return true
        elsif val == "0"
          return false
        else
          raise ArgumentError, "unable to convert #{val.class}:#{val} into #{klass}"
        end
      end
#      puts "dest class: #{dest.class}"
      return dest
    elsif klass == String
      return val.to_s
    end
#    puts "HERE"
    nil
  end

  # This function does basic auto-formatting of symbol names
  # to labels.

  def Text.symbol_to_label(symbol)
    symbol.to_s.gsub(/[-_.]/, " ").capitalize
  end

  def Text.label_to_symbol(label)
    label.gsub(/ /, "-").downcase
  end

  def Text.utf8_encode(str)
    s = ""
    str.each_char do |c|
      begin
        x = c.unpack("C")[0]
        if x < 128
          s << c
        else
          s << "\\u%04x" % c.unpack("U")[0]
        end
      rescue => e
        # FIXME:  this represents a character conversion
        # error, but we're going to replace it with a '?' like
        # other implementations.
        s << "?"
      end
    end
    s
  end

  def Text.utf8_decode(str)
    str.gsub(/\\u([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])/) do
      [ $1.hex ].pack("U*")
    end 
  end

  # This method is basically lifted from Sinatra's base.rb
  # for handling the routes.  However, we just needed to
  # support glob-ish URI references instead of named
  # parameters, so that's been removed.
  #
  # NOTE:  it doesn't exactly support the full UNIX shell glob
  # syntax (yet)

  def Text.uri_glob_to_regex(path)
    return path if path.nil? || "" == path
    special_chars = %w{ . + ( )}
    pattern = path.gsub(/[\*#{special_chars.join}]/) do |match|
      case match
      when '*'
        "(.*?)"
      when *special_chars
        Regexp.escape(match)
      end
    end
    /^#{pattern}$/
  end
end
end
