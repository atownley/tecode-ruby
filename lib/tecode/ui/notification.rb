#--
######################################################################
#
# Copyright 2008, Andrew S. Townley
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
# File:     notification.rb
# Author:   Andrew S. Townley
# Created:  Sat Nov  1 14:27:10 GMT 2008
#
######################################################################
#++

module TECode
module UI

  # This class is used to relay notifications from one sender
  # to another sender's registered listeners.

  class NotificationRelay
    def initialize(sender, listeners)
      @listeners = listeners
      @sender = sender
    end

    def method_missing(method, *args, &block)
      args[0] = @sender
      @listeners.each { |l| l.send(method, *args, &block) }
    end
  end

  module ViewChangeNotifier
    def register_view_change_observer(observer)
      observers = (@view_change_observers ||= [])
      observers << observer if !observers.include? observer
    end

    def unregister_view_change_observer(observer)
      observers = (@view_change_observers ||= [])
      observers.delete(observer)
    end

  protected
    def fire_view_changed
      observers = (@view_change_observers ||= [])
      observers.each { |o| o.view_changed(self) }
    end
  end

end
end
