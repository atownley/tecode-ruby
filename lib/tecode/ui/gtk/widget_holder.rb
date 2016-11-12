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
# File:     widget_holder.rb
# Author:   Andrew S. Townley
# Created:  Sat Nov  1 14:27:10 GMT 2008
#
######################################################################
#++

module TECode
module UI
module Gtk

  # This class provides a holder for a Gtk2 widget that can be
  # used as the basis for building more complex controls and
  # widgets.

  class WidgetHolder
    attr_reader :widget
    
    def initialize(widget)
      @widget = widget
    end

    def editable
      @widget.editable
    end

    def editable=(val)
      @widget.editable=(val)
    end

    def sensitive
      @widget.sensitive
    end

    def sensitive=(val)
      @widget.sensitive = val
    end

    def cursor=(cursor)
      @widget.window.cursor = cursor if !@widget.window.nil?
    end

    def cursor
      @widget.window.cursor
    end

    def grab_focus
      @widget.grab_focus
    end

    def show
      @widget.show
    end

    def hide
      @widget.hide
    end

    def show_all
      @widget.show_all
    end

  protected
    def widget=(widget)
      @widget = widget
    end
  end

end
end
end
