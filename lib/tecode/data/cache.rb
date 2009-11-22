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
# File:        cache.rb
# Author:      Andrew S. Townley
# Created:     Sat Nov 21 18:03:55 GMT 2009
#
######################################################################
#++

require 'tecode/time'

module TECode
module Data
 
  # This class provides an implementation of a memory-based,
  # LRU cache bounded by the number of objects being managed.

  class Cache
    attr_reader :max_size, :hits, :accesses

    def initialize(max_size = 5000)
      @max_size = max_size
      @objects = {}
      @index = []
      @hits = 0
      @accesses = 0
      @name = "Cache-#{self.hash}"
    end

    # This method resets the size of the cache to the new
    # value.  If the new size is smaller than the old value,
    # then the cache is appropriately trimmed of objects

    def max_size=(newsz)
      if newsz < size
        (size - newsz).times do
          old = @index.delete_at(0)
          @objects.delete(old.obj)
        end
        resort
      end

      @max_size = newsz
    end

    def hit_rate
      ((1.0 * @hits) / @accesses) * 100
    end

    def size
      @index.size
    end

    # This method caches the object.  If the object replaces
    # another object in the cache, the old object is returned

    def cache(object)
      self[object] = object
    end

    def <<(obj)
      cache(obj)
    end

    # This allows caching with a different key than the
    # object.  The same behavior still applies with regard to
    # LRU accesses

    def []=(key, val)
      old = nil

      if size == max_size
        old = @index.delete_at(0)
        @objects.delete(old.key)
        old = old.obj
      end

      decorator = KeyedDecorator.new(val)
      decorator.key = key
      @objects[key] = decorator
      @index << decorator
      resort
      old
    end

    # This method locates the specified object in the cache.
    # If it isn't found, the method returns nil

    def [](key)
      @accesses += 1
      val = @objects[key]
      if val
#        puts "Reset timer for #{key}"
        @hits += 1
        val.reset
        val = val.obj
        resort
      end
#      if (@accesses % 100) == 0
      if (@accesses % 20) == 0
        STDERR.puts "Cache '#{@name}' hit rate: #{hit_rate}% over #{accesses} accesses"
      end
     val
    end

    # This method deletes the specific object from the cache
    # and returns the value.
    #
    # NOTE:  This method assumes that the key and the value
    # are the same.  If not, you need to use the delete_if!
    # method instead.

    def delete(object)
      val = @objects.delete(object)
      if val
        @index.delete(val)
      end
      val
    end

    # This method removes a particular value from the cache if
    # it meets the given criteria

    def delete_if!(&block)
      @objects = @objects.delete_if do |key, val|
        if block.call(key, val)
          @index.delete(val)
          true
        end
      end
    end

    # This method returns the values in the cache.

    def values
      @objects.keys
    end

    def dump
      @index.each do |td|
        puts "#{td.obj} - #{td.elapsed}: #{td.created.sec}.#{td.created.usec}"
      end
    end

  private
    def resort
#      puts "Before"
#      dump
      @index.sort!
#      puts "After"
#      dump
#      puts "----"
    end

    class KeyedDecorator < TECode::TimerDecorator
      attr_accessor :key
    end
  end

end
end
