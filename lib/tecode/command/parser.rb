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
      @exec_list = []

      add_options(help_options)
      add_options(OptionGroup.new("Output options",
        Option.new("verbose",
          :description => "display informational status messages during execution"),

        Option.new("debug",
          :description => "display debugging information messages during execution")
        )
      )

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
      when :requires, :requires_one
        obj = RequiresOneOptionConstraint.new(self, *args)
      else
        return
      end

      @constraints << obj
    end

    # This method will actually execute all of the matched
    # options and call the optional block to allow command
    # execution to take place.
    #
    # The timing of when the optional block is called is
    # dependent on whether the value of 'default' is present
    # or not.  If present, 'default' specifies a default
    # option to execute of no options are matched and the
    # block is executed prior to the options to allow
    # appropriate environment configuration to be performed
    # before the default is executed.
    #
    # If the default is not present, then the options are
    # executed before the optional block is called, and the
    # main application processing can be performed within the
    # optional block.

    def execute(args, default = nil, &block)
      parse(args)
      check_constraints
      pre_execute_block
      execute_options(default) if !default
      if block
        block.call(extra_args)
      end
      execute_options(default) if default
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

    def verbose?
      self["verbose"].matched?
    end

    def debug?
      self["debug"].matched?
    end

    def info(msg)
      STDERR.puts msg if verbose?
    end

    def warn(msg)
      STDERR.puts "warning: " << msg
    end

    def debug(msg)
      STDERR.puts msg if debug?
    end

    def err_exit(exit_code, msg)
      error(msg, exit_code)
    end

    def error(msg, exit_code = nil)
      msg = "error:  #{msg}"
      if exit_code
        msg << ".  Exiting."
      end
      STDERR.puts msg
      exit exit_code if exit_code
    end

  protected
    def parse(args)
      while args.length > 0 do
        s = args.shift
#        puts "processing: '#{s}'"
        opt = nil
        val = nil
        case s
        when /^--([^=\s]+)=?(.*)$/
          name = $1
          val = $2
          opt = @lnames[name]
          if !opt
            warn "skipping unrecognized option '#{s}'..."
            next
          end
          if opt && opt.expects_arg? && "" == val
            val = args.shift
          end
        when /^-([^-\s])$/
          name = $1
          opt = @snames[name]
          if !opt
            warn "skipping unrecognized option '#{s}'..."
            next
          end
          if opt && opt.expects_arg?
            val = args.shift
          end
        end

        if opt
          opt.matched(val)
          @exec_list << opt if opt.has_block?
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
          Kernel.exit c.exit_status
        end
      end
    end

    def pre_execute_block
    end

    def execute_options(default = nil)
      @exec_list.each do |o|
        o.execute(self)
      end
      if default && @exec_list.length == 0
        default = self[default]
        default.execute(self, true) 
      end
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
