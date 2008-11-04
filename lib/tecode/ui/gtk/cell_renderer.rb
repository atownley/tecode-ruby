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
# File:     cell_renderer.rb
# Author:   Andrew S. Townley
# Created:  Sat Nov  1 21:23:51 GMT 2008
#
######################################################################
#++

module TECode
module UI
module Gtk

  ENTRY = ::Gtk::Entry.new

  class IndexedCellRenderer < ::Gtk::CellRendererText
    attr_accessor :index

    def initialize(treeview, idx)
      super()
      @index = idx
    end

    def editable=(val)
      super

      if !val
        super.background_gdk = ENTRY.style.bg(Gtk::StateType::INSENSITIVE)
        super.background_set = true
      else
        super.background_set = false
      end
    end
  end

  class Widget
    attr_reader :widget
    
    def initialize(widget)
      @widget = widget
    end
  end

  class FormField < Widget
    attr_accessor :label, :widget_class, :field_widget, :label_widget

    def initialize(label, widget = ::Gtk::Entry.new)
      super(widget)
      @label = label
      @label_widget = ::Gtk::Label.new("#{label}:")
      @field_widget = widget
      @dirty = false
      @editable = true
    end

    def editable?
      @editable
    end

    def editable=(val)
      @editable = val
      ::Gtk.queue do
        if editable?
          field_widget.sensitive = false
          field_widget.editable = false
        else
          field_widget.sensitive = true
          field_widget.editable = true
        end
      end
    end

    def dirty?
      @dirty
    end

    def text
      ::Gtk.queue { @widget.text }
    end

    def text=(val)
      val = val.to_s
      ::Gtk.queue do
        if val != @widget.text
          @dirty = true
        end
        @widget.text = val
      end
    end

    def show_all
      @label_widget.show
      @field_widget.show
    end

    # This is a bit of a hack, but...

    def signal_connect(signal, &block)
      __internal_signal_connect(widget, signal, &block)
    end

    alias sensitive= editable=
    alias sensitive? editable?

  protected
    def __internal_signal_connect(widget, signal, &block)
      widget.signal_connect(signal) do |*args|
        block.call(self, *args)
      end
    end
  end

  class ComboFormField < FormField
    def initialize(label)
      super(label, ::Gtk::ComboBoxEntry.new)
      @combo_model = ::Gtk::ListStore.new(String)
      widget.model = @combo_model
      widget.child.completion = ::Gtk::EntryCompletion.new
      widget.child.completion.model = widget.model
      widget.child.completion.text_column = 0
      widget.child.completion.inline_completion = true

      @choices = []
    end

    def text
      ::Gtk.queue { widget.child.text }
    end

    def text=(val)
      val = val.to_s
      ::Gtk.queue do
        if val != widget.child.text
          @dirty = true
          widget.child.text = val
        end
      end
    end

    def choices=(choices)
      ::Gtk.queue do
        widget.model.clear
        choices.each { |c| widget.append_text(c) }
        widget.child.text = "" if !choices.include? widget.child.text
        @choices = choices
      end
    end

    def choices
      @choices
    end

    def select(val)
      ::Gtk.queue do
        if val.is_a? Fixnum
          widget.active = val
        else
          idx = @choices.index(val)
          if !idx.nil?
            widget.active = idx
          else
            widget.text = ""
          end
        end
      end
    end

    def signal_connect(signal, &block)
      case signal
      when "focus-out-event", "activate"
        __internal_signal_connect(widget.child, signal, &block)
      else
        super
      end
    end

  private
  end

  class Form < Widget
    def initialize(border_width = 5)
      super(::Gtk::Table.new(1, 2))
      @fields = {}
      @fields_by_index = []
      widget.border_width = border_width
    end

    def <<(field)
      add(field)
    end

    # Can add fields either explicitly via instances of the
    # FormField class, or you can just specify the label to
    # use.

    def add(field)
      if field.is_a? String
        field = FormField.new(field)
      end

      return self if @fields_by_index.include? field

      @fields_by_index << field
      @fields[field.label] = field
      self
    end

    def remove(field)
      @fields.delete(field.label)
      @fields_by_index.delete(field)
    end
      
    def [](key)
      if key.is_a? Fixnum
        return @fields_by_index[key]
      end
      @fields[key]
    end

    def size
      @fields.size
    end

    def show_all
      ::Gtk.queue do
        widget.hide
        widget.resize(@fields.size, 2)

        @fields_by_index.each_index do |i|
          field = @fields_by_index[i]
          field.label_widget.xalign = 1
          field.label_widget.justify = ::Gtk::Justification::RIGHT
          widget.attach(field.label_widget, 0, 1, i, i + 1, ::Gtk::AttachOptions::FILL)
          widget.attach_defaults(field.field_widget, 1, 2, i, i + 1)
        end

        widget.show_all
      end
    end

    def clear
      @fields_by_index.each { |f| f.text = "" }
    end

    def sensitive=(val)
      @fields_by_index.each { |f| f.sensitive = val }
    end 
      
    alias rows size
  end

end
end
end
