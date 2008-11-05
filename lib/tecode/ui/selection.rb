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
# File:     selection.rb
# Author:   Andrew S. Townley
# Created:  Wed Nov  5 08:05:05 GMT 2008
#
######################################################################
#++

module TECode
module UI

  # This class represents a selection from a selection source.
  # It must be initialized with the mime type for the
  # selection group and an indication if the selection
  # contents can be modified.

  class Selection
    attr_reader :mime_type

    def initialize(mime_type, mutable = false)
      @mime_type, @mutable = mime_type, mutable
      @items = []
      @mime_types = [ "text/plain" ]
    end

    def mutable?
      @mutable
    end

    # This method returns all of the mime types to which the
    # selection can be converted.

    def mime_types
      @mime_types.clone
    end

    def <<(item)
      @items << SelectionItem.new(item, mutable?)
    end

    def [](index)
      @items[index]
    end

    def [](index, val)
      raise ArgumentError, "selection is not mutable!" if !mutable?

      @items[index] = SelectionItem.new(val, mutable?)
    end

    def each(&block)
      @items.each(&block)
    end

    def to_s
      s = ""
      each { |item| s << item.to_s }
      s
    end

    def to_mime_type(mime_type)
      if !mime_types.include? mime_type
        raise ArgumentError, "unable to convert to requested mime-type '#{mime_type}'.  Supported mime types are:  #{mime_types.join(', ')}"
      end

      selection_to_mime_type(mime_type)
    end

  protected
    # This method allows derived classes a hook to perform
    # mime type conversions of the selection.
    
    def selection_to_mime_type(mime_type)
      to_s
    end

  private
    class SelectionItem
      def initialize(item, mutable)
        if mutable
          @item = item
        else
          @item = item.clone.freeze
        end
      end

      def method_missing(method, *args, &block)
        @item.send(method, *args, &block)
      end
    end
  end
 
  # This module provides mix-in support to allow objects to
  # notify listeners that the current selection has changed.
  # It supports a single observer method:
  #
  # +selection_changed(sender, selection)

  module SelectionNotifier
    def register_selection_observer(observer)
      observers = (@selection_observers ||= [])
      observers << observer if !observers.include? observer
    end

    def unregister_selection_observer(observer)
      observers = (@selection_observers ||= [])
      observers.delete(observer)
    end

  protected
    def fire_selection_changed(selection)
      observers = (@table_model_observers ||= [])
      observers.each { |o| o.table_row_inserted(self, row, value) }
    end
  end

end
end
