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
# File:     context_menu.rb
# Author:   Andrew S. Townley
# Created:  Fri Nov  7 17:44:52 GMT 2008
#
######################################################################
#++

module TECode
module UI
module Gtk

  class ContextMenuHandler
    attr_reader :press_event, :release_event, :menu

    def initialize(gtk_widget, menu = nil, &block)
      if menu.nil? && block.nil?
        raise ArgumentError, "must specify either a menu or builder block"
      end

      gtk_widget.signal_connect("button_press_event") do |widget, event|
        rc = false
        if event.event_type == Gdk::Event::BUTTON_PRESS && \
            event.button == 3
          @press_event = event
          @release_event = nil
          show_context_menu(event, event.button, event.time)
          rc = true
        end
        rc
      end

#      gtk_widget.signal_connect("button_release_event") do |widget, event|
#        if event.event_type == Gdk::Event::BUTTON_PRESS && \
#            event.button == 3
#          @release_event = event
#          @press_event = nil
#          next false
#        end
#      end

      gtk_widget.signal_connect("popup_menu") do |widget, event|
        show_context_menu(nil, 0, Gdk::Event::CURRENT_TIME)
        true
      end
      
      @widget = gtk_widget
      @menu = menu
      @menu_builder = block
    end
    
    def show_menu
      show_context_menu(nil, 0, Gdk::Event::CURRENT_TIME)
    end

  protected
    def show_context_menu(event, button, time)
      if @menu_builder.nil? 
        @menu.popup(nil, nil, button, time)
      else
        menu = @menu_builder.call(self, @widget, @menu, @event)
        menu.popup(nil, nil, button, time) if !menu.nil?
      end
    end
  end
end
end
end
