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

  # This class provides a set of standard behavior for
  # Gtk::CellRenderers that can be easily applied to custom
  # Ruby classes derived from Gtk::CellRenderer and friends.

  module CellRendererHelper
    attr_reader   :column_index

    def initialize(col_index, table_view)
      super()
      @column_index = col_index
      @table_view = table_view
    end

    def editable=(val)
      super

      if !val
        super.background_gdk = ENTRY.style.bg(::Gtk::StateType::INSENSITIVE)
        super.background_set = true
      end
    end
  end

  class CompletionCellRendererText < ::Gtk::CellRendererText
    include CellRendererHelper
    attr_accessor :editing_path, :completion
    
    def initialize(col_index, table_view, gtk_treeview)
      super(col_index, table_view)
      self.yalign = 0
      self.single_paragraph_mode = false
      self.wrap_width = 250
      self.editable = table_view.model.is_column_editable? col_index
     
      # take care of the signal handlers
      self.signal_connect("editing-started") do |sender, editable, path|
        next if !table_view.model.editable? || !table_view.model.is_column_editable?(col_index) || !editable?

        sender.editing_path = path
        path = ::Gtk::TreePath.new(path)
        row = path.indices[0]

        if gtk_treeview.selection.selected_rows.size > 0
          gtk_treeview.selection.unselect_all
          gtk_treeview.selection.select_path(path)
        end

        if sender.editable? && row == table_view.model.size
          table_view.model.new_row_at(row)
        end

        # set up cell completion
        if editable.is_a? ::Gtk::Entry
          if !sender.completion.nil?
            sender.completion.attach(editable)
          end
          # need to force a re-read of the underlying model
          # since this may be a sentinal row with invalid text
          val = TECode::Text.convert(String, 
                  table_view.model.value_for(row, sender.column_index)).to_s
          editable.text = val if editable.text != val
        end

        # Set up traversal functionality.  Some of the code
        # below is based on the example from
        # http://www.ruby-forum.com/topic/130202#581785

        editable.signal_connect("key-press-event") do |widget, event|
          rc = false
          nextcol = 0
          newrow = row
          if Gdk::Keyval.to_name(event.keyval) == "Tab"
            if event.state.shift_mask?
              # FIXME:  this doesn't appear to get this far.
              # Need to figure out how to ensure it gets to
              # the editable!
              nextcol = sender.column_index - 1
              if nextcol < 0
                nextcol = table_view.model.column_count - 1
                newrow = row - 1
              end
            else
              nextcol = sender.column_index + 1
              if nextcol == table_view.model.column_count
                newrow = row + 1
                nextcol = 0
                while(!table_view.model.is_column_editable?(nextcol) && nextcol < table_view.model.column_count)
                  nextcol += 1
                end
              end
              if newrow == table_view.model.row_count \
                  && !table_view.settings[TableView::SHOW_SENTINAL_ROW]
                newrow = 0
              end
            end

            widget.editing_done
            widget.hide
            gtk_treeview.set_cursor(::Gtk::TreePath.new(newrow.to_s),
                    gtk_treeview.get_column(nextcol), true)
            rc = true
          end
          rc
        end

        editable.grab_focus
      end

      self.signal_connect("editing-canceled") do |sender|
        sender.editing_path = nil
      end
    end
  end

end
end
end
