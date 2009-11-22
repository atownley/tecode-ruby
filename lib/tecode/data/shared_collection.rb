#--
######################################################################
#
# Copyright (c) 2009, Andrew S. Townley
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
# File:        shared_collection.rb
# Author:      Andrew S. Townley
# Created:     Sun Nov 22 09:55:45 GMT 2009
#
######################################################################
#++

require 'thread'

module TECode
module Data
  
  # This class provides common functionality to manage shared
  # views of a collection.

  class SharedCollection
    def initialize(collection, manage_locks = true)
      @collection = collection
      @sessions = {}
      @mutex = Mutex.new
      @manage_locks = manage_locks
    end

    def size
      lock do
        @collection.size
      end
    end

    def collection=(val)
      lock do
        @sessions.values.each do |value|
          value.invalidate!
        end
        @collection = val
      end
    end

    def [](index)
      lock do
        @collection[index]
      end
    end

  protected
    def manage_session(session)
      @mutex.synchronize { @sessions[session] = session }
      session
    end

  private
    def lock(&block)
      if @manage_locks
        @mutex.synchronize do
          return block.call
        end
      else
        return block.call
      end
    end
  end

  # This class provides the base behavior to allow graceful
  # invalidation of shared access to a collection that might
  # change.

  class CollectionSession
    def initialize(shared_collection)
      @collection = shared_collection
      @valid = true
    end

    def size
      @collection.size
    end

    def invalidate!
      @valid = false
    end

    def valid?
      @valid
    end
  end

  # This error is raised when the session is invalid.

  class InvalidSessionError < StandardError
  end

end
end
