#--
######################################################################
#
# Copyright 2009, Andrew S. Townley
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
# File:     context.rb
# Created:  Wed Nov 25 10:36:01 GMT 2009
#
#####################################################################
#++

module TECode::Test
 
  # This class provides a testing context which is independent
  # of any testing framework but which can be used with any of
  # them to externalize the notion of context.
  #
  # It is based on the notion of Test Base states that we had
  # during my testing days at Informix.  Script and test
  # contexts are instances of this class.

  class Context
    attr_reader :name, :description, :vars
    
    def self.register_context(name, context)
      reg = (@@contexts ||= {})
      reg[name] = context

#      puts "registered context '#{name}'"
#      puts @@contexts.inspect
    end

    def self.[](key)
#      puts "lookup '#{key}'; @@contexts.nil? #{@@contexts.nil?}"
      return if @@contexts.nil?
      @@contexts[key]
    end

    def initialize(name, desc = nil, &block)
      @setup_proc = block
      @teardown_proc = nil
      @name = name
      @description = desc
      @vars = {}

      Context.register_context(name, self)
    end

    def [](key)
      @vars[key.to_s]
    end

    def []=(key, val)
      @vars[key.to_s] = val
    end

    # this method is called to establish the context.  If a
    # block was given during initialization, it is used here
    # unless derived classes implement this method.

    def setup
      @setup_proc.call(self) if @setup_proc
    end

    # This method is called to clean up and restore the
    # context.
    
    def teardown
    end

    def setup_proc
      m = self.method(:setup)
      proc { |*args| m.call }
    end

    def teardown_proc
      m = self.method(:teardown)
      proc { |*args| m.call }
    end

    def set(var, val)
      self[var] = val
    end

    def get(var)
      self[var]
    end

    def method_missing(method, *args, &block)
      if @vars.has_key? method.to_s
        return @vars[method.to_s]
      end
      super
    end
  end
end
