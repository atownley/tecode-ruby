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
# File:     option.rb
# Author:   Andrew S. Townley
# Created:  Sun  8 Aug 2010 18:31:09 IST
#
######################################################################
#++

module TECode
module Command
  
  class Option
    attr_reader :long_name, :short_name, :arg, :arg_default, :value

    def initialize(long_name, *args, &block)
      @long_name = long_name
      @short_name = args.shift if !args[0].is_a? Hash
      @options = (args[0].is_a?(Hash) ? args[0] : {})
      @arg_default = @options[:arg_default]
      @has_arg = (@options[:has_arg] ||= false)
      @block = block
      @matched = false
    end

    def execute(parser)
      if @block.nil?
        return
      end

      @block.call(parser, parser.extra_args)
    end

    def description
      s = @options[:description]
      if s && arg_default
        s << " (default is #{arg_default})"
      end
      s
    end

    def expects_arg?
      @has_arg
    end

    def help
      @options[:help] || "ARG"
    end

    def matched?
      @matched
    end

    def name
      @long_name
    end

    def show_arg_in_help?
      true
    end

    def matched(arg)
      if expects_arg? && arg.nil?
        raise ArgumentError, "option '#{name}' expects an argument!"
      end

      @arg = arg
      @matched = true
    end

    def reset
      @arg = nil
      @matched = false
    end

    def value
      @arg || @arg_default
    end

    def to_s
      name
    end

    def to_str
      to_s
    end
  end

  class RepeatableOption < Option
    def initialize(*args)
      super
      @args = []
    end

    def arg
      @args[0]
    end

    def value
      @args
    end

    def reset
      super
      @args = []
    end

    def matched(arg)
      super
      @args << arg
    end
  end

  class OptionGroup
    attr_reader :description

    def initialize(description, options)
      @description = description
      @options = options
      @index = {}
      @options.each { |o| @index[o.name] = o }
    end

    def each(&block)
      @options.each(&block)
    end

    def [](key)
      @index[key]
    end
  end

end
end
