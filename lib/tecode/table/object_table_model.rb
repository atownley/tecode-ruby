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
# File:     object_table_model.rb
# Author:   Andrew S. Townley
# Created:  Fri Oct 31 16:47:30 GMT 2008
#
######################################################################
#++

module TECode
module Table

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

    def column_name(index)
      TECode::Text.symbol_to_label(@column_attrs[index])
    end

    def column_class(index)
      if row_count > 0
        return value_for(0, index).class
      end
      String
    end

    def append_row(row, editable = nil)
      check_row_type(row)
      super(ObjectAttributeColumnAdapter.new(row, @column_attrs), editable)
    end

    def insert_row(index, row, editable = nil)
      check_row_type(row)
      super(index, ObjectAttributeColumnAdapter.new(row, @column_attrs), editable)
    end

    def value_for(row, col)
      check_index_bounds(row, col)
#      return nil if !self[row].respond_to? @column_attrs[col]
      self[row][col]
    end

    def set_value_for(row, col, value)
      check_index_bounds(row, col)
      old = self[row][col]
      return if old == value
      if !value.is_a?(old.class) && do_type_conversion?
        value = TECode::Text.convert(old.class, value)
      end
      self[row][col] = value
      self[row].row_edited = true if old != value
      fire_row_changed(row, self[row])
    end

  protected
    def check_row_type(row)
      if !row.is_a? @row_class
        raise ArgumentError, "specified row #{row} is not compatible with the model's row class: #{@row_class}"
      end
    end
  end

  # This class provides an alternative Object TableModel that
  # can be used to represent the properties of a single object
  # as a table.
 
  class ObjectPropertiesTableModel < BaseRowModel
    attr_accessor :property_names, :object

    def initialize(object, property_names)
      super()
      @object, @property_names = object, property_names
      @editable = true
      load_rows(object)
    end

    def column_count
      2
    end

    def is_column_editable?(col)
      return false if col == 0 || !@object.respond_to?("#{@property_names[col]}=".to_sym)
      true
    end

    def column_name(index)
      if index == 0
        return "Attribute"
      end
      "Value"
    end

    def insert_row(index, row, editable = nil)
      raise RuntimeError, "operation not supported"
    end

    def delete_row(index)
      raise RuntimeError, "operation not supported"
    end

    def value_for(row, col)
      check_index_bounds(row, col)
      val = self[row][col]
      if col == 0
        return TECode::Text.symbol_to_label(val)
      end
      val
    end

    def set_value_for(row, col, value)
      check_index_bounds(row, col)
      old = value_for(row, col)
      return if old == value
      if !value.is_a?(old.class) && do_type_conversion?
        value = TECode::Text.convert(old.class, value)
      end
      self[row][col] = value
      self[row].row_edited = true if old != value
      fire_row_changed(row, self[row])
    end

  protected
    def load_rows(object)
      @property_names.each do |key|
        append_row(ObjectAttributeRowAdapter.new(object, key))
      end
    end
  end

  # This class is used to provide a column-centric view of an
  # object's attributes for easy use with the TableModel
  # interface.

  class ObjectAttributeColumnAdapter
    include EditableMixin

    attr_reader :object, :attributes, :format_fn

    def initialize(object, attributes, &formatting_block)
      @object, @attributes, @format_fn = object, attributes, formatting_block

      # make sure we're dealing with symbols
      @attributes.each_index do |i|
        if !@attributes[i].is_a? Symbol
          @attributes[i].to_s.to_sym
        end
      end
    end

    def each(&block)
      @attributes.each_index do |i|
        block.call(self[i])
      end
    end

    def [](index)
      if format_fn.nil?
        return @object.send(@attributes[index])
      end
      format_fn.call(index, @attributes[index], object)
    end

    def []=(index, val)
      sym = "#{@attributes[index]}=".to_sym
      if !@object.respond_to? sym
        raise RuntimeError, "column #{index} is not editable"
      end
      @object.send(sym, val)
    end

    def method_missing(method, *args, &block)
      @object.send(method, *args, &block)
    end
  end

  # This class is used to provide a row-centric view of an
  # object's attributes for easy use with the TableModel
  # interface.

  class ObjectAttributeRowAdapter
    include EditableMixin
    
    attr_reader :attribute, :object, :format_fn
    
    def initialize(object, attribute, &formatting_block)
      @object, @attribute, @format_fn = object, attribute.to_s.to_sym, formatting_block
    end

    def each(&block)
      [ @attribute, value ].each(&block)
    end

    def [](index)
      if index == 0
        return TECode::Text.symbol_to_label(@attribute)
      end
      value
    end

    def []=(index, val)
      sym = "#{@attribute}=".to_sym
      if index == 0 || !@object.respond_to?(sym)
        raise RuntimeError, "column #{index} is not editable"
      end
      @object.send(sym, val)
    end

    def method_missing(method, *args, &block)
      @object.send(method, *args, &block)
    end

  protected
    def value
      if format_fn.nil?
        return @object.send(@attribute)
      end
      format_fn.call(@attribute, object)
    end
  end

end
end
