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
require 'parsedate'

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
  # from here: # http://hcicrossroads.blogspot.com/2011/01/regular-expression-for-multiple-forms.html
  SCIDIGIT  = %r{^[+|-]?\d\.?\d{0,}[E|e|X|x](10)?[\^\*]?[+|-]?\d+$}
  QLITERAL  = %r{(?:"(?:[^"\\]|\\.)*")|'(?:[^'\\]|\\.)*'}
  SHELLVAR  = %r{(.|^)\$\{?([^\}\s]*)\}?}
  
  # This function should be used whenever user-input strings
  # need to be parsed into the corresponding runtime value.

  def self.parse_string(str)
    return str if !str.is_a? String

    val = str
    case val 
      when /^#{HEXDIGIT}$/ then val = val.hex
      when /^[-+]?\\0[1-7][0-7][0-7]$/ then val = val.oct
      when /^[-+]?\d+$/ then val = val.to_i
      when /^#{SCIDIGIT}$/ then val = val.to_f
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

  # This method is used to perform simple variable
  # substitution in strings supporting UNIX Bourne Shell
  # variable syntax, e.g. $var or ${var} based on the values
  # of the specified Hash instance.
  #
  # If a block is given, it is given the opportunity to
  # provide a value for the variable instead of the hash.

  def self.shell_expand(str, vars = ENV, &block)
    # Have to do some contortions to ensure that we aren't
    # trying to substitute an escaped '$'.
    # FIXME: there's probably a more elegant way to do this...
    return str if !str || !str.is_a?(String)

    str.gsub(TECode::Text::SHELLVAR).each do |match|
      s = $1
      var = $2
      # eat the backslash and give the match back 
      next match[1..-1] if s == "\\"
      if block
        val = block.call(var)
      else
        if (val = vars[var] || vars[var.to_sym])
          val
        else
          raise ArgumentError, "error: variable '$#{var}' not defined."
        end
      end
      "#{s}#{val}"
    end
  end
  
  # This method is a bit of a hack to help parse
  # internationalized dates using the same characters as
  # strftime(3).  If no format is given, it will fall back to
  # ParseDate

  def self.parse_date(str, fmt = nil, utc = false)
    return str if !str
    if !fmt
      rval = ParseDate.parsedate(str)
    else
      params = []
      regex = ""
      fmt.scan(/%([a-zA-Z*])+|([-:\/\s])/) do |match|
#        puts "match: #{match.inspect}"
        params << match[0] if match[0]
        case(match[0] || match[1])
        when 'A'
          # full weekday name
          regex << '(\w+)'
        when 'a'
          # local abbreviated weekday name
          regex << '(\w{3})'
        when 'B'
          # full month name
          regex << '(\w+)'
        when 'b', 'h'
          # abbreviated month name
          regex << '(\w{3})'
        when 'C'
          regex << '(\d{2})'
        when 'c'
          # national representation of time and date
          raise ArgumentError, "'standard' locale parsing is not currently supported"
        when 'D'
          # '%m/%d/%y'
          rval = ParseDate.parsedate(str)
          break
        when 'd'
          # day of month (01-31)
          # NOTE: we're being more flexible than we need to be
          regex << '(\d{1,2})'
        when 'E', 'O'
          raise ArgumentError, "POSIX locale extensions are not currently supported"
        when 'e'
          # month as decimal number (1-31) with optional
          # leading blank for single digits
          regex << '\s*(\d{1,2})'
        when 'F'
          # '%Y-%m-%d'
          rval = ParseDate.parsedate(str)
          break
        when 'G'
          # year with century
          regex << '(\d{4})'
        when 'g'
          # year without century (00-99)
          regex << '(\d{2})'
        when 'H'
          # 24 hour clock (00-23)
          regex << '(\d{1,2})'
        when 'I'
          # 12 hour cloc (01-12)
          regex << '(\d{1,2})'
        when 'j'
          # day of year as decimal number
          regex << '(\d{3})'
        when 'k'
          # hour (24-hour clock) as decimal with optional
          # leading blank
          regex << '\s*(\d{1,2})'
        when 'l'
          # hour (12-hour clock) as decimal number (1-12) with
          # optional leading blanks
          regex << '\s*(\d{1,2})'
        when 'M'
          # minute as decimal (leading zeros)
          regex << '(\d{2})'
        when 'm'
          # month as decimal (leading zeros)
          # note, we're relaxint this
          regex << '(\d{1,2})'
        when 'n'
          # newline (ignored)
        when 'p'
          # national am/pm designation
          raise ArgumentError, "AM/PM locale equivalents not currently supported"
        when 'R'
          # equivalent to '%H:%M'
          regex << '(\d{2}:\d{2})'
        when 'r'
          # equivalent to '%I:%M:%S %p'
          regex << '(\d{2}:\d{2}:\d{2} \w+)'
        when 'S'
          # seconds as decimal number
          regex << '(\d{2})'
        when 's'
          # seconds since epoch
          regex << '(\d+)'
        when 'T'
          # equivalent to '%H:%M:%S'
          regex << '(\d{2}:\d{2}:\d{2})'
        when 'U'
          # week number of the year
          regex << '(\d{2})'
        when 'u'
          # weekday starting with Monday
          regex << '(\d)'
        when 'V'
          # week number in year
          regex << '(\d{2})'
        when 'v'
          # equivalent to '%e-%b-%Y'
          regex << '\s*(\d{1,2}-\w{3}-\d{4}'
        when 'W'
          # Week number for the year as decimal
          regex << '(\d{2})'
        when 'w'
          # weekday (Sunday as first day)
          regex << '(\d)'
        when 'X'
          # national representation of the time
          raise ArgumentError, "national time representation not supported"
        when 'x'
          # national representation of the date
          raise ArgumentError, "national date representation not supported"
        when 'Y'
          # year with century
          regex << '(\d{4})'
        when 'y'
          # year without century
          regex << '(\d{2})'
        when 'Z'
          # time zone name
          regex << '(\w{3})'
        when 'z'
          # UTC offset with leading +/-
          regex << '([-+]\d{4})'
        when '+'
          # national representation similar to date(1)
          raise ArgumentError, "national datetime representation not supported"
        when '/'
          regex << '\/'
        else
          regex << (match[0] || match[1])
        end
      end
      regex = Regexp.new(regex)
# puts "PARAMS: #{params.inspect}" 
# puts "REGEX: #{regex.inspect}" 
      # parsedate gives year (0), month (1), day of month (2),
      # hour (3), minute (4), second (5), timezone (6), 
      # day of week (7)
      #
      # FIXME: this isn't as robust as it probably should
      # be...
      rval = [ nil, nil, nil, nil, nil, nil, nil, nil ]
      if match = str.match(/#{regex}/)
        match.captures.each do |c|
          case(params.shift)
          when 'z', 'Z'
            rval[6] = c
          when 'y'
            c = c.to_i
            if c < 30
              rval[0] = 2000 + c
            else
              rval[0] = 1900 + c
            end
          when 'Y'
            rval[0] = c.to_i
          when 'm'
            rval[1] = c.to_i
          when 'd'
            rval[2] = c.to_i
          when 'H'
            rval[3] = c.to_i
          when 'M'
            rval[4] = c.to_i
          when 'S'
            rval[5] = c.to_i
          when 'w', 'u'
            rval[7] = c.to_i
          end
        end
      else
        raise ArgumentError, "Failed to parse '#{str}' with format '#{fmt}' (regex: #{regex.inspect})"
      end
    end

  puts "RVAL: #{rval.inspect}"
    if utc
      Time.utc(*rval)
    else
      Time.local(*rval)
    end
  end
end
end
