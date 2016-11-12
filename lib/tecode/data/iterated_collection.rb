#--
######################################################################
#
# Copyright (c) 2005-2016, Andrew S. Townley
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
# File:        collection_iterator.rb
# Author:      Andrew S. Townley
# Created:     Sun Nov 22 09:55:45 GMT 2009
#
######################################################################
#++

require 'thread'

module TECode
module Data
  
  # This class allows multi-session views of a collection via
  # an iterator.  Iterators are simply pointers into the
  # collection and expose a very simple interface for forward
  # navigation.

  class IteratedCollection < SharedCollection
    def new_session(&block)
      manage_session(IteratorSession.new(self, &block))
    end
  end

  # This class represents a specific iterator session
  # within the given IteratedCollection instance

  class IteratorSession < CollectionSession
    attr_reader :index

    # This method creates a new iterator session.  The block
    # parameter allows processing of the value returned by
    # next so that a transformation or lookup can be applied.

    def initialize(mc, &block)
      super
      @index = -1
      @block = block
    end

    def reset
      raise InvalidSessionError, "Collection session has been invalidated" if !valid?
      @index = -1
    end

    def each(&block)
      0.upto(size - 1) do |i|
        raise InvalidSessionError, "Collection session has been invalidated" if !valid?
        @index = i
        block.call(read(index))
      end
    end

    def has_next?
      raise InvalidSessionError, "Collection session has been invalidated" if !valid?
      @index < size - 1
    end

    def next
      raise InvalidSessionError, "Collection session has been invalidated" if !valid?
      @index += 1
      read(index)
    end

  private
    def read(idx)
      val = @collection[idx]
      if @block
        val = @block.call(val)
      end
      val
    end
  end

end
end
