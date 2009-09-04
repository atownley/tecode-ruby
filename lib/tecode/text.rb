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

module TECode
module Text
  DIGIT     = %r{[-+]?\d+(?:\.?\d+)?}
  QLITERAL  = %r{"(?:[^"\\]|\\.)*"}
  
  # This function should be used whenever user-input strings
  # need to be parsed into the corresponding runtime value.

  def Text.parse_string(str)
    val = str
    case val 
      when /^[-+]?0\d+$/ then val = val.oct
      when /^[-+]?0x[a-fA-F\d][a-fA-F\d]*$/ then val = val.hex
      when /^[-+]?\d+$/ then val = val.to_i
      when /^#{DIGIT}$/ then val = val.to_f
      when /^#{DIGIT}%$/ then val = val.to_f / 100
      when /^:(.*)/
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
end
end
