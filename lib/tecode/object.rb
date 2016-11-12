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
# File:     object.rb
# Author:   Andrew S. Townley
# Created:  Thu Feb  4 17:16:53 GMT 2010
#
######################################################################
#++

module TECode
  
  # This class is used to restrcit the public API of a Ruby
  # object by explicitly methods to be called only if they're
  # on the allow_method list.

  class RestrictedDelegator
    def initialize(delegate, allow_methods = [])
      @delegate = delegate
      @allow = {}
      allow_methods.each do |m|
        m = m.to_sym if m.is_a? String
        @allow[m] = true
      end
      self.freeze
    end

    def method_missing(method, *args, &block)
      if @allow[method]
        return @delegate.send(method, *args, &block)
      end
      super
    end
  end
end
