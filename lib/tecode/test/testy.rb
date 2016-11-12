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
# File:     testy.rb
# Created:  Wed Nov 25 10:58:10 GMT 2009
#
#####################################################################
#++

require 'tecode/test'
require 'testy'

ver = Testy.version.split(".")
if ver[0].to_i == 0 && ver[1].to_i < 5
  raise RuntimeError, "error:  Your version of Testy is not new enough.  Needs version 0.5.0 or later."
end

# This class redefines the context method of Testy so that it
# can be used with the external TECode::Test::Context
# registry.  This is kinda ugly, but it's necessary... honest! ;)

module Testy
  class Test

    alias :__context_orig :context
    def context(name = nil, &block)
      rc = nil
      if name
        tectx = TECode::Test::Context[name]
        if tectx
          rc = __context_orig(name, &block)
          val = contexts.delete(name)
          contexts[tectx.description] = val
        end
      else
        rc = __context_orig(name, &block)
      end
      rc
    end

    def method_missing(method, *args, &block)
      @@maxdepth = 50
      depth = (@@depth ||= 1)
      @@depth += 1
#      puts "depth: #{@@depth}"
      if @@depth < @@maxdepth
        ctx = self.contexts.values.last.tecode_context
        ctx.method_missing(method, *args, &block)
      else
        super
      end
    end

    # We're adding a reference to the associated
    # TECode::Test::Context instance for the given name

    class Context
      attr_accessor :tecode_context
      alias :__orig_initialize :initialize

      def initialize(*args, &block)
        if args.length > 0 && args[0] && '' != args[0]
          @tecode_context = TECode::Test::Context[args[0]]
          if @tecode_context
            args[0] = @tecode_context.description
            if args.length < 2
              args << @tecode_context.setup_proc
            end
            if args.length < 3
              args << @tecode_context.teardown_proc
            end
          end
        end
        __orig_initialize(*args, &block)

      end
    end
  end
end
