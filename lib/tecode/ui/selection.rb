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
    include TECode::UI::ChangeNotifier

    attr_reader :mime_type

    def initialize(mime_type, mutable = false, &block)
      @mime_type, @mutable = mime_type, mutable
      @items = []
      @mime_types = [ TECode::MimeType::Text::PLAIN ]
      @mime_types << @mime_type if !@mime_type.nil?
      @block = block
      register_change_observer(self)
    end

    def changed(sender)
      @block.call(sender) if !@block.nil?
    end

    def mutable?
      @mutable
    end

    def is_mime_type?(mtype)
      mtype == mime_type
    end

    # This method returns all of the mime types to which the
    # selection can be converted.

    def mime_types
      @mime_types.clone
    end

    def <<(item)
      @items << SelectionItem.new(pre_add_item(item), mutable?)
      fire_changed
    end

    def [](index)
      @items[index]
    end

    def []=(index, val)
      raise ArgumentError, "selection is not mutable!" if !mutable?

      @items[index] = SelectionItem.new(pre_add_item(val), mutable?)
      fire_changed
    end

    def each(&block)
      @items.each(&block)
    end

    def reverse_each(&block)
      @items.reverse_each(&block)
    end

    def size
      @items.size
    end
    alias length size

    def to_s
      s = ""
      each { |item| s << item.to_s }
      s
    end

    def to_mime_type(mime_type)
      if !mime_types_include? mime_type
        raise ArgumentError, "unable to convert to requested mime-type '#{mime_type}'.  Supported mime types are:  #{mime_types.join(', ')}"
      end

      selection_to_mime_type(mime_type)
    end

    def clear
      @items.clear
    end

    def delete(object)
      item = @items.delete(object)
      if !item.nil? && item.respond_to?(:was_deleted)
        item.was_deleted
      end
    end

  protected
    # This method allows derived classes a hook to perform
    # mime type conversions of the selection.
    
    def selection_to_mime_type(mime_type)
      to_s
    end

    # Derived classes should implement this method to do
    # special preparation on the items prior to their being
    # added to the selection.  It saves constant
    # implementation of the modification methods.
    #
    # Implementations MUST return a reference to the item
    # being added.

    def pre_add_item(item, *args)
      item
    end

  private
    def mime_types_include?(mtype)
      @mime_types.each do |mt|
        if mtype.to_s == mt.to_s
          return true
        end
      end
      false
    end

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

      def respond_to?(sym)
        @item.respond_to? sym
      end

      def to_s
        @item.to_s
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
      observers = (@selection_observers ||= [])
      observers.each { |o| o.selection_changed(self, selection) }
    end
  end

  # This class provides default handling for generic
  # selections of ruby objects.

  class RubyObjectSelection < Selection
    def initialize(mutable)
      super(TECode::MimeType::Application::X_RUBY_OBJECT, mutable)
    end
  end

  # This class provides default handling for selections of
  # URIs.
  
  class UriListSelection < Selection
    def initialize(mutable)
      super(TECode::MimeType::Application::URI_LIST, mutable)
    end
  end

  # This class provides default handling for selections of
  # plain text.


  class PlainTextSelection < Selection
    def initialize(mutable)
      super(nil, mutable)
    end
  end
end
end
