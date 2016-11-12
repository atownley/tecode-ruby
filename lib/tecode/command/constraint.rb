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
# File:     constraint.rb
# Author:   Andrew S. Townley
# Created:  Sun  8 Aug 2010 23:57:17 IST
#
######################################################################
#++

module TECode
module Command
  
  class OptionConstraint
    attr_reader :parser, :message, :exit_status

    def initialize(*args)
      @parser, @exit_status, @message = *args
    end
  end

  class MutexOptionConstraint < OptionConstraint
    def initialize(parser, exit_status, option1, option2, message = nil)
      super(parser, exit_status, message)
      @option1 = parser[option1]
      @option2 = parser[option2]
    end

    def message
      super || \
        "error:  cannot specify both '#{@option1}' and '#{@option2}'"
    end

    def ok?
      !(@option1.matched? && @option2.matched?)
    end
  end

  class RequiredOptionConstraint < OptionConstraint
    def initialize(parser, exit_status, option, message = nil)
      super(parser, exit_status, message)
      @option = parser[option]
    end

    def message
      super || \
        "error:  option '#{@option}' is required."
    end

    def ok?
      @option.matched?
    end
  end

  class RequiresAnyOptionConstraint < OptionConstraint
    def initialize(parser, exit_status, option, *args)
      super(parser, exit_status)
      @option = parser[option]
      @list = args.collect { |x| parser[x] }
    end

    def message
      items = @list.collect { |x| "'#{x}'" }.join(", ")
      super || \
        "error:  option '#{@option}' requires one of: #{items}"
    end

    def ok?
      if @option.matched?
        @list.each { |x| return true if x.matched? }
        false
      else
        true
      end
    end
  end

  class RequiresOneOptionConstraint < OptionConstraint
    def initialize(parser, exit_status, option, arg)
      super(parser, exit_status)
      @option = parser[option]
      @arg = parser[arg]
    end

    def message
      super || \
        "error:  option '#{@option}' requires '#{@arg}'"
    end

    def ok?
      return true if !@option.matched?
      @option.matched? && @arg.matched?
    end
  end

end
end
