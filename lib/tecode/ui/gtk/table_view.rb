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
# File:     table_view.rb
# Author:   Andrew S. Townley
# Created:  Wed Nov  5 08:00:32 GMT 2008
#
######################################################################
#++

module TECode

module MimeType
  # Define specialized mime types for use within the tecode
  # library
  module TECode
    TABLE_ROW               = "application/x-tecode-table-row"
  end
end

module UI
module Gtk

  class TreeSelection < TECode::UI::Selection
    SINGLE        = ::Gtk::SELECTION_SINGLE
    MULTIPLE      = ::Gtk::SELECTION_MULTIPLE

    def initialize(mutable, model)
      super(TECode::MimeType::TECode::TABLE_ROW, mutable)
      if !model.nil? && model.respond_to?(:mime_types)
        @mime_types = @mime_types.concat(model.mime_types).uniq
      end
      @model = model
    end

  protected
    def selection_to_mime_type(mime_type)
      rc = []

#      puts "TreeSelection#selection_to_mime_type(#{mime_type})"
      each do |row|
        if !@model.nil? && @model.respond_to?(:row_to_mime_type)
          rc << @model.row_to_mime_type(row.index, mime_type)
        else
          rc << super
        end
      end
      rc
    end
  end

  # This class provides a reference to a particular table row

  class RowRef
    attr_reader :index, :object

    def initialize(model, index, object, mutable)
      @model, @index, @object = model, index, object
      if !mutable
        @object = object.clone.freeze
      end
    end

    def method_missing(method, *args, &block)
      @object.send(method, *args, &block)
    end
  
    def was_changed
      @model.row_changed(@index)
    end

    def was_deleted
      @model.delete_row(@index)
    end
  end

  # This class provides a "standard" GtkTreeView configured as
  # a table (no tree functionality).

  class TableView < WidgetHolder
    include TECode::UI::SelectionNotifier
    include TECode::UI::ViewChangeNotifier
    include TECode::UI::ContextMenuDelegator
    include TECode::UI::SignalHandler

    attr_reader   :model

    EDITABLE                    = "editable"
    SHOW_SENTINAL_ROW           = "show-sentinal-row"
    SHOW_DIRTY_ROWS             = "show-dirty-rows"
    DIRTY_ROW_COLOR             = "dirty-row-color"
    SENTINAL_TEXT               = "sentinal-text"
    RULE_HINTING                = "rule-hinting"
    DRAW_GRID                   = "draw-grid"
    SELECTION_MODE              = "selection-mode"
    AUTOMATIC_TYPE_CONVERSION   = "automatic-type-conversions"

    def initialize(editable = nil, config = {})
      super(nil)
      @renderers = {}
      @completion_models = {}
      
      ensure_default(config, EDITABLE, editable)
      ensure_default(config, SHOW_SENTINAL_ROW, true)
      ensure_default(config, SHOW_DIRTY_ROWS, true)
      ensure_default(config, DIRTY_ROW_COLOR, DEFAULT_DIRTY_COLOR)
      ensure_default(config, RULE_HINTING, true)
      ensure_default(config, DRAW_GRID, false)
      ensure_default(config, AUTOMATIC_TYPE_CONVERSION, true)
      ensure_default(config, SENTINAL_TEXT, DEFAULT_SENTINAL_TEXT)
      ensure_default(config, SELECTION_MODE, TreeSelection::MULTIPLE)
      self.settings = config

      @empty_model = TECode::Table::ArrayTableModel.new(0)
      class << @empty_model
        def column_name(index)
          ""
        end
      end
      @empty_model.editable = settings[EDITABLE]
      @empty_model << [ "" ]
      @widget = init_view
    end

    # This method uses absolute indexing of the columns from
    # when the table was initialized, so it won't necessarily
    # reflect the current view column ordering

    def get_column_completion_model(col)
      @completion_models[col]
    end

    def set_column_completion_model(col, model, index, &block)
      @completion_models[col] = [ model, index, block ]
      return if @renderers[col].nil?

      @renderers[col].completion = TableModelEntryCompletion.new(*@completion_models[col])
    end

    def model=(new_model)
      @model.unregister_table_model_observer(self) if !@model.nil?
      @model = new_model
      @model.register_table_model_observer(self)
      if settings[EDITABLE].nil?
        settings[EDITABLE] = @model.editable?
      end
#      puts "model row count = #{new_model.row_count}"
      reset_table
      fire_view_changed
    end

    def clear
      self.model.clear if !self.model.nil?
      @tree.model.clear if !@tree.model.nil?
    end

    def editable?
      settings[EDITABLE]
    end

    def show_dirty?
      settings[SHOW_DIRTY_ROWS]
    end

    # this method enables/disables highlighting dirty rows in
    # the table with an alternative color.  The color may be
    # specified using the "dirty-row-color" key in the
    # settings hash

    def show_dirty=(val)
      settings[SHOW_DIRTY_ROWS] = val
    end

    def editable=(val)
      settings[EDITABLE] = val
      @empty_model.editable = val
      @tree.columns.each_index do |i|
        val = false if !@model.column_is_editable?(i)
        @tree.columns[i].cell_renderers.each do |renderer|
          renderer.editable = val
        end
      end
    end

    def settings
      @settings
    end

    def settings=(val)
      @settings = val
    end

    def selection
      sel = TreeSelection.new(editable?, @model)
      return sel if @model.nil?
      
      @tree.selection.selected_each do |model, path, iter|
        idx = path.indices[0]
        if idx < @model.row_count
          sel << RowRef.new(@model, idx, @model[idx], editable?)
        else
          if !editable? || !settings[SHOW_SENTINAL_ROW]
            raise RuntimeError, "internal state error:  selected row in the control is '#{idx}', but we only have #{@model.row_count} rows in the model!"
          end
        end
      end
      sel
    end

    def clear_selection
      @tree.selection.unselect_all
    end

    def select_row(row)
      clear_selection
      select_rows([row])
      path = ::Gtk::TreePath.new((row).to_s)
      ## FIXME:  I've no idea how to do this properly!
      @tree.scroll_to_cell(path, nil, false, 0, 0) if !@tree.window.nil?
    end

    def select_rows(rows)
      rows.each do |row|
        iter = @tree.model.get_iter(::Gtk::TreePath.new(row.to_s))
        @tree.selection.select_iter(iter) if !iter.nil?
      end
    end

    def select_rows_with_regex(regex, max = nil)
      rows = model.row_count - 1
      cols = model.column_count - 1
      0.upto(rows) do |i|
        0.upto(cols) do |j|
          if model[i][j] =~ /#{regex}/i
            iter = @tree.model.get_iter(::Gtk::TreePath.new(i.to_s))
            @tree.selection.select_iter(iter)
            if !max.nil?
              break if @tree.selection.count_selected_rows == max
            end
          end
        end
      end
    end

    def select_rows_with_column_regex(col, regex, max = nil)
      rows = model.row_count - 1
      cols = model.column_count - 1
      
      if !col.is_a? Fixnum
        0.upto(cols) do |i|
          if model.column_name(i) =~ /#{col}/i || \
              model.column_name(i) =~ /#{TECode::Text.label_to_symbol(col)}/i
            col = i
            break
          end
        end
        if !col.is_a? Fixnum
          raise ArgumentError, "unable to locate column for name '#{col}'"
        end
      end

      0.upto(rows) do |i|
        if model[i][col] =~ /#{regex}/
          iter = @tree.model.get_iter(::Gtk::TreePath.new(i.to_s))
          @tree.selection.select_iter(iter)
          if !max.nil?
            break if @tree.selection.count_selected_rows == max
          end
        end
      end
    end

    ### Implement the table change observer interface ###
    
    def table_row_inserted(sender, index, object)
#      puts "***** Table inserted row[#{index}] = #{object}"
      path = ::Gtk::TreePath.new((index).to_s)
      iter = @tree.model.get_iter(path)
#      puts "***** SENDER.size? #{sender.size}"
#      puts "***** ITER = #{iter.inspect}"
      if index == 0 && iter.nil?
        iter = @tree.model.append
      else
#        path = ::Gtk::TreePath.new((index - 1).to_s)
        if !settings[SHOW_SENTINAL_ROW]
          @tree.model.insert_after(iter)
#        else
#          iter = @tree.model.append
        end
      end
      if iter.nil?
        # FIXME:  there's gotta be a better way to figure
        # out what we need to do here...
        iter = @tree.model.append
      end
      display_row(iter, index)

      count = 0
      @tree.model.each do |x|
        count += 1
      end
#      puts "****** INTERNAL MODEL HAS #{count} ROWS"

      if index == sender.row_count - 1
        add_sentinal(@tree.model)
      end
    end

    def table_row_deleted(sender, index, object)
#      puts "**** DELETE row #{index}"
#      puts "***** SENDER.size? #{sender.size}"
      path = ::Gtk::TreePath.new(index.to_s)
      iter = @tree.model.get_iter(path)
      @tree.model.remove(iter) if !iter.nil?
      
      # FIXME:  Hackfest begins!
      if sender.size == 0
        @tree.model.clear
      end
    end

    def table_row_changed(sender, index, object)
#      puts "table row changed: #{index}"
      path = ::Gtk::TreePath.new(index.to_s)
      iter = @tree.model.get_iter(path)
      display_row(iter, index)
    end

    def show_all
      self.widget.show_all if !self.widget.nil?
    end

  private
    DEFAULT_DIRTY_COLOR   = "#f0e7f3"
    DEFAULT_SENTINAL_TEXT = "< click to add a new row >"

    def ensure_default(hash, key, val)
      if !hash.include? key
        hash[key] = val
      end
      hash
    end

    def dirty_col
#      puts "dirty_col = #{@model.column_count}"
      @model.column_count
    end

    def editable_col
#      puts "editable_col = #{@model.column_count + 1}"
      @model.column_count + 1
    end
    
    def editable_row_col
#      puts "editable_row_col = #{@model.column_count + 2}"
      @model.column_count + 2
    end

    def init_view
      scroller = ::Gtk::ScrolledWindow.new
      scroller.set_policy(::Gtk::POLICY_AUTOMATIC, ::Gtk::POLICY_AUTOMATIC)
      @tree = ::Gtk::TreeView.new
      @tree.enable_grid_lines = settings[DRAW_GRID] ? ::Gtk::TreeView::GridLines::BOTH : ::Gtk::TreeView::GridLines::NONE
      @tree.rules_hint = settings[RULE_HINTING]
      @tree.selection.mode = settings[SELECTION_MODE]
      @tree.selection.signal_connect("changed") do |sender|
        fire_selection_changed(selection)
      end
      @tree.signal_connect("row-activated") do |sender, path, column|
        row = path.indices[0]
        signal_emit("row-activated", self, row, column)
      end

      # FIXME:  figure out how to handle context menu items
      init_menus

      scroller.add(@tree)
      scroller.show_all
    end

    def init_menus
      @tree.signal_connect("button_press_event") do |widget, event|
        if event.kind_of? Gdk::EventButton and event.button == 3
          show_context_menu(event, event.button, event.time)
          next true
        end
        false
      end

      @tree.signal_connect("popup_menu") do
        show_context_menu(nil, 0, Gdk::Event::CURRENT_TIME)
      end
    end

    def show_context_menu(event, button, time)
      path = nil
      menu = nil
      if !event.nil?
        path = @tree.get_path(event.x, event.y)
      end
      if path.nil?
        menu = signal_emit("populate-popup", self, menu)
        if !menu.nil?
          menu.show_all
          menu.popup(nil, nil, button, time)
        end
        return
      else
        sel_iter = @tree.model.get_iter(path[0])
        if @tree.selection.selected_rows.size == 0 || !@tree.selection.path_is_selected?(path[0])
          @tree.selection.unselect_all
          @tree.selection.select_iter(sel_iter)
        end
        menu = signal_emit("populate-popup", self, menu, selection)
        if !menu.nil?
          menu.popup(nil, nil, button, time)
        end
      end
    end

    def add_sentinal(model)
      return if !settings[SHOW_SENTINAL_ROW] || !editable?

      added_text = false
      iter = model.append
      0.upto(@model.column_count - 1) do |i|
#        puts "checking column '#{@model.column_name(i)}'; editable? #{@model.is_column_editable?(i)}"
        if @model.is_column_editable? i
          iter[i] = settings[SENTINAL_TEXT]
          added_text = true
          break
        end
      end
      iter[dirty_col] = false
      iter[editable_col] = true
      iter[editable_row_col] = true
      
      if !added_text
#        puts @model
        raise RuntimeError, "internal error:  unable to append sentinal text to row because no columns are editable!"
      end
    end

    def display_row(iter, row_index)
#      puts "display row[#{row_index}]"
      0.upto(@model.column_count - 1) do |col|
        coltype = @tree.model.get_column_type(col)
        val = @model.value_for(row_index, col)
        if coltype != val.class && settings[AUTOMATIC_TYPE_CONVERSION]
          val = TECode::Text.convert(coltype, val)
        end
        iter[col] = val
      end
      iter[dirty_col] = @model[row_index].dirty?
      iter[editable_col] = editable? && @model[row_index].editable?
      iter[editable_row_col] = @model[row_index].editable?
    end

    def reset_table
      clear_selection
      @tree.model.clear if !@tree.model.nil?
      @tree.columns.reverse_each do |tvc|
        @tree.remove_column(tvc)
      end

      # FIXME:  When it's possible to build an adapter
      # directly implementing the Gtk::TreeModel interface,
      # this should go away...
      cols = @model.column_count
      args = []
      0.upto(cols - 1) do |i|
        # This fun and games is necessary so we don't end up
        # with default values displayed in the sentinal row.
        if settings[SHOW_SENTINAL_ROW]
          args << String
        else
          args << @model.column_class(i)
        end
      end
      # Add some renderer bookkeeping columns:
      # 1. row dirty?
      # 2. row editable
      # 3. disabled background set
      # 4. disabled background color
      args << TrueClass << TrueClass << TrueClass << Gdk::Color
      @tree.model = ::Gtk::ListStore.new(*args)

      0.upto(@model.row_count - 1) do |row|
        display_row(@tree.model.append, row)
      end

      0.upto(cols - 1) do |i|
        renderer = @renderers[i]
        if renderer.nil?
          renderer = CompletionCellRendererText.new(i, self, @tree)
        end
        if !@completion_models[i].nil? && renderer.completion.nil?
          renderer.completion = @completion_models[i]
        elsif !@completion_models[i].nil?
          renderer.completion = TableModelEntryCompletion.new(*@completion_models[col])
        end
        renderer.signal_connect("edited") do |sender, path, new_value|
          cell_editing_completed(sender, path, new_value)
        end

        attrs = { :text => i }
#        puts "column #{i} editable? #{@model.is_column_editable?(i)}"
        if @model.is_column_editable? i
          renderer.background = settings[DIRTY_ROW_COLOR]
          attrs[:background_set] = dirty_col
        end
        attrs[:editable] = editable_col
        
        tc = ::Gtk::TreeViewColumn.new(@model.column_name(i), renderer, attrs)
        tc.set_sort_column_id(i)
        tc.reorderable = true
        tc.resizable = true
        @tree.append_column(tc)
      end

#      puts "table editable? #{editable?}; show sentinal? #{settings[SHOW_SENTINAL_ROW]}"
      if editable?
        add_sentinal(@tree.model)
      end
    end

    def cell_editing_completed(renderer, path_str, new_value)
      path = ::Gtk::TreePath.new(path_str)
      row = path.indices[0]

      @model.set_value_for(row, renderer.column_index, new_value)
    end
  end
end
end
end
