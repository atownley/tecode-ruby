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
# File:     autohelp.rb
# Author:   Andrew S. Townley
# Created:  Sun  8 Aug 2010 21:04:13 IST
#
######################################################################
#++

module TECode
module Command
  
  module AutoHelp
    def help_options
      OptionGroup.new("Help options",
        Option.new("help", "?",
          :description => "show this help message") do |me, parser, args|
            parser.help()
            Kernel.exit 0
          end,

        Option.new("usage",
          :description => "show brief usage message") do |me, parser, args|
            parser.usage()
            Kernel.exit 0
          end
      )
    end

    def format_usage(groups)
      l = [ app_name ]
      groups.reverse_each do |desc, options|
        options.each do |o|
          line = "["
          x = []
          x << "-#{o.short_name}" if o.short_name
          x << "--#{o.long_name}" if o.long_name
          line << x.join("|")
          if o.expects_arg?
            line << " " << o.help
          end
          line << "]"
          l << line
        end
      end
      l << arg_help if arg_help
      s = "Usage:  " << l.join(" ")
      s.wrap(80, 8)
    end

    def format_help(groups)
      list = []
      line = "Usage:  " << app_name << " [OPTIONS...] "
      line << arg_help if arg_help
      line << "\n"
      list << line
      groups.reverse_each do |desc, options|
        desc = desc || "#{app_name} options"
        s = desc.wrap(80) << ":\n"
        options.each do |o|
          line = "  "
          x = [] 
          x << "-#{o.short_name}" if o.short_name
          x << "--#{o.long_name}" if o.long_name
          line << x.join(", ")
          if o.expects_arg?
            line << "=" << o.help
          end
          spc = 35 - line.length
          spc = 0 if spc < 0
          line << " " * (spc)
          line << o.description
          s << line.wrap(80, 33) << "\n"
        end
        list << s
      end 

      list.join("\n")
    end
  end

end
end
