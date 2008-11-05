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
# File:     table_model.rb
# Author:   Andrew S. Townley
# Created:  Fri Oct 31 16:47:30 GMT 2008
#
######################################################################
#++

module TECode
module UI
  
  # This is a mix-in that manages table modle notifications
  #
  # TableModels provide notifications to registered
  # observer objects about table events via the
  # TableModelObserver informal protocol.  This protocol is
  # defined as follows:
  #
  # TableModelObserver
  #   +table_row_inserted(sender, row_index, row_value)
  #   +table_row_deleted(sender, row_index, row_value)
  #   +table_row_changed(sender, row_index, row_value)

  module TableModelNotifier
    def register_table_model_observer(observer)
      observers = (@table_model_observers ||= [])
      observers << observer if !observers.include? observer
    end

    def unregister_table_model_observer(observer)
      observers = (@table_model_observers ||= [])
      observers.delete(observer)
    end

  protected
    def fire_row_inserted(row, value)
      observers = (@table_model_observers ||= [])
      observers.each { |o| o.table_row_inserted(self, row, value) }
    end

    def fire_row_deleted(row, value)
      observers = (@table_model_observers ||= [])
      observers.each { |o| o.table_row_deleted(self, row, value) }
    end

    def fire_row_changed(row, value)
      observers = (@table_model_observers ||= [])
      observers.each { |o| o.table_row_changed(self, row, value) }
    end
  end

  # This is a mix-in that allows centralized bounds checking

  module TableModelHelper
    attr_reader :column_count, :row_count

  protected
    def check_editable(row)
      if !self.editable? 
        raise ArgumentError, "model is not editable"
      end
      if row < row_count && !self[row].editable?
        raise ArgumentError, "model is not editable"
      end
    end

    def check_index_bounds(row, col)
      if row >= row_count
        raise ArgumentError, "requested row #{row} out of bounds.  Model has #{row_count} rows."
      end

      if col >= column_count
        raise ArgumentError, "requested column #{col} out of bounds.  Model has #{column_count} columns."
      end
    end
  end
    
  # This class provides a general table model implementation.
  # It is particularly useful for GTK+ since at the moment, it
  # isn't really easy to create custom table models.
  #
  # This class uses a row creation delegate which must respond
  # to the create_row(model) method and return a new row which
  # is compatible with the model.

  class BaseRowModel
    include TableModelNotifier
    include TableModelHelper

    attr_reader :row_factory

    def initialize
      @editable = false
      @rows = []
    end

    def editable?
      @editable
    end

    # This method associates the row factory with the table
    # model, allowing new rows to be created on demand.  The
    # table model cannot be edited without a valid factory.

    def row_factory=(factory)
      if !factory.respond_to? :create_row
        raise ArgumentError, "specified factory (#{factory}) does not respond to :create_row"
      end

      @factory = factory
      @editable = (factory.nil? ? false : true)
      if editable?
        @rows.each { |row| row.editable = true }
      end
    end

    def row_editable?(row)
      return false if !editable?

      @rows[row].editable?
    end

    def set_row_editable(row, val)
      @rows[row].editable = val
    end

    # This method is normally used by views which are allowed
    # to create new rows in the model.  The use of the row
    # factory allows the view to not need to know
    # implementation details about the implementation of the
    # rows.

    def new_row_at(index)
      raise ArgumentError, "no row factory set" if @factory.nil?

      insert_row(index, @factory.create_row(self))
    end

    def append_row(row, editable = nil)
      editable = editable? if editable.nil?
      @rows << RowHolder.new(row, editable)
      fire_row_inserted(@rows.size - 1, row)
    end
    alias << append_row

    def insert_row(index, row, editable = nil)
      check_editable(index)

      editable = editable? if editable.nil?
      @rows.insert(index, RowHolder.new(row, editable))
      fire_row_inserted(index, row)
    end

    def delete_row(index)
      check_editable(index)

      row = @rows.delete_at(index)
      fire_row_deleted(index, row)
      row
    end

    def [](index)
      @rows[index]
    end

    def []=(index, val)
      check_editable(index)

      @rows[index] = val
      fire_row_updated(index, val)
    end

    def row_count
      @rows.size
    end
    alias length row_count
    alias size row_count

    def each_row(&block)
      @rows.each(&block)
    end

  private
    class RowHolder
      def initialize(row, editable)
        @row = row
        @editable = editable
      end

      def editable?
        @editable
      end

      def editable=(val)
        @editable = val
      end

      def method_missing(method, *args, &block)
        @row.send(method, *args, &block)
      end
    end
  end

  # This class provides a simple TableModel based on using
  # arrays for the columns.  It is effectively a matrix, but
  # probably isn't the best choice to use for non-trivial
  # circumstances.

  class ArrayTableModel < BaseRowModel
    def initialize(num_columns)
      super()
      @columns = num_columns
      self.row_factory = self
    end

    def column_count
      @columns
    end

    def create_row(factory) 
      Array.new(column_count)
    end

    def append_row(row, editable = nil)
      check_row_size(row)
      super(row, editable)
    end

    def insert_row(index, row, editable = nil)
      check_row_size(row)
      super(index, row, editable)
    end

    def value_for(row, col)
      check_index_bounds(row, col)
      self[row][col]
    end

    def set_value_for(row, col, value)
      check_index_bounds(row, col)
      self[row][col] = value
      fire_row_changed(row, self[row])
    end

  protected
    def check_row_size(row)
      if row.size < column_count
        raise ArgumentError, "supplied row has less than #{column_count} elements"
      elsif row.size > column_count
        STDERR.puts "warning:  adding row with #{row.size} columns to table model with #{column_count} columns!"
      end
    end
    
  end

  # This class provides a simple TableModel based on property
  # values for object instances stored in the table.  The
  # table is initialized with the ordered symbol names
  # representing the columns in the model.  If you want
  # different column ordering, you simply change the order of
  # the symbols in the constructor.

  class ObjectTableModel < BaseRowModel

    # The constructor takes the class name for rows in the
    # table, allowing some level of inheritance.  The model
    # will return nil values for any attributes not present
    # for a row--provided they are all part of the inheritance
    # for the specified class.

    def initialize(klass, column_attrs)
      super()
      @row_class = klass
      @column_attrs = column_attrs
    end

    def column_count
      @column_attrs.size
    end

    def append_row(row, editable = nil)
      check_row_type(row)
      super(ArrayObjectAdapter.new(row, @column_attrs), editable)
    end

    def insert_row(index, row, editable = nil)
      check_row_type(row)
      super(ArrayObjectAdapter.new(row, @column_attrs), editable)
    end

    def value_for(row, col)
      check_index_bounds(row, col)
      return nil if !self[row].respond_to? @column_attrs[col]
      self[row].send @column_attrs[col]
    end

    def set_value_for(row, col, value)
      check_index_bounds(row, col)
      self[row][col] = value
      fire_row_changed(row, self[row])
    end

  protected
    def check_row_type(row)
      if !row.is_a? @row_class
        raise ArgumentError, "specified row #{row} is not compatible with the model's row class: #{@row_class}"
      end
    end

  private
    class ArrayObjectAdapter
      def initialize(obj, cols)
        @obj = obj
        @cols = cols
      end

      def each(&block)
        @cols.each do |sym|
          block.call(@obj.send(sym))
        end
      end

      def [](index)
        @obj.send(@cols[index])
      end

      def []=(index, val)
        @obj.send("#{@cols[index]}=".to_sym, val)
      end

      def method_missing(method, *args, &block)
        @obj.send(method, *args, &block)
      end
    end
  end

  # This class provides a TableModel backed by a hash.
  # Unfortunately, for mutable models, they rows aren't
  # guaranteed to be in any particular order.  Each key will
  # be a row in the table.
 
  class HashTableModel < BaseRowModel
    def initialize(hash)
      super()
      @hash = hash
      @keys = hash.keys
      self.row_factory = self
      hash.each_key do |key|
        append_row(hash)
      end
    end

    def create_row(sender)
      @hash
    end

    def column_count
      2
    end
  
    def insert_row(index, row, editable = nil)
      super(index, row, editable)
      @keys << ""
    end

    def delete_row(index)
      @keys.delete_at(index)
      super(index)
    end

    def value_for(row, col)
      check_index_bounds(row, col)
      key = @keys[row]
      if col == 0
        return key
      end
      return @hash[key]
    end

    def set_value_for(row, col, value)
      check_index_bounds(row, col)
      key = @keys[row]
      if col == 0
        oldkey = @keys[row]
        @keys[row] = value
        @hash[value] = @hash[oldkey]
        @hash.delete(oldkey)
      else
        @hash[key] = value
      end
    end

    def each_row(&block)
      @keys.each do |key|
        block.call HashRowAdapter.new(@hash, key)
      end
    end

  private
    class HashRowAdapter
      def initialize(hash, key)
        @row = [ key, hash[key] ]
      end

      def each(&block)
        @row.each(&block)
      end
     
      def [](index)
        @row[index]
      end
    end
  end
end
end
