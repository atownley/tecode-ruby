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
# File:     parser.rb
# Author:   Andrew S. Townley
# Created:  Sun  8 Aug 2010 18:26:51 IST
#
######################################################################
#++

require 'orderedhash'

module TECode
module Command
  
  class Parser
    include AutoHelp

    attr_reader :app_name, :arg_help, :extra_args

    def initialize(app_name, arg_help = nil, options = {})
      @app_name = app_name
      @option_index = {}
      @groups = OrderedHash.new
      @lnames = {}
      @snames = {}
      @constraints = []
      @extra_args = []
      @arg_help = arg_help

      add_options(help_options)

      if File.exist? app_name
        @app_name = File.basename(app_name)
      end
    end

    # Adds a new OptionGroup instance to the parser.
    #
    # NOTE:  groups are displayed in the reverse order in
    # which they are added to allow for proper processing of
    # library or shared groups across different tools

    def add_options(group)
      @groups[group.description] = group
      group.each { |o| register_option(o) }
    end

    def add_constraint(type, *args)
      obj = nil
      case type
      when :mutex
        obj = MutexOptionConstraint.new(self, *args)
      when :required
        obj = RequiredOptionConstraint.new(self, *args)
      when :requires_any
        obj = RequiresAnyOptionConstraint.new(self, *args)
      else
        return
      end

      @constraints << obj
    end

    def execute(args, &block)
      parse(args)
      check_constraints
      execute_options
      block.call(extra_args)
    end

    def help
      puts format_help(@groups)
    end

    def usage
      puts format_usage(@groups)
    end

    def [](key)
      ( @lnames[key] || @snames[key] )
    end

  protected
    def parse(args)
      while args.length > 0 do
        s = args.shift
        opt = nil
        val = nil
        case s
        when /^--([^-=\s]+)=?(.*)$/
          name = $1
          val = $2
          opt = @lnames[name]
          if opt && opt.expects_arg? && "" == val
            val = args.shift
          end
        when /^-([^-\s])$/
          name = $1
          opt = @snames[name]
          if opt && opt.expects_arg?
            val = args.shift
          end
        end

        if opt
          opt.matched(val)
        else
          @extra_args << s
        end 
      end
    end

    def check_constraints
      @constraints.each do |c|
        if !c.ok?
          STDERR.puts c.message << ".  Exiting."
          usage
          exit c.exit_status
        end
      end
    end

    def execute_options
      @option_index.values.each { |o| o.execute(self) if o.matched? }
    end

    def register_option(option)
      if @option_index.has_key? option.name
        warn "warning:  option with name '#{option.name}' already registered.  Skipped."
        return
      end
        
      @option_index[option.name] = option
      @lnames[option.long_name] = option
      @snames[option.short_name] = option
    end

    def reset
      @option_idex.values.each { |o| o.reset }
    end
  end

end
end
