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
# File:     array_table_model.rb
# Author:   Andrew S. Townley
# Created:  Fri Oct 31 16:47:30 GMT 2008
#
######################################################################
#++

module TECode
module Table

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

    def column_class(index)
      if row_count > 0
        value_for(0, index).class
      end
      String
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
    def check_row_size(row)
      if row.size < column_count
        raise ArgumentError, "supplied row has less than #{column_count} elements"
      elsif row.size > column_count
        STDERR.puts "warning:  adding row with #{row.size} columns to table model with #{column_count} columns!"
      end
    end
    
  end

end
end
