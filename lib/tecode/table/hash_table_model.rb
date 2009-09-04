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
# File:     hash_table_model.rb
# Author:   Andrew S. Townley
# Created:  Fri Oct 31 16:47:30 GMT 2008
#
######################################################################
#++

module TECode
module Table

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

    def column_name(index)
      if index == 0
        return "Key"
      end
      "Value"
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
#      puts "row: #{row}; col: #{col}; value: #{value.class}:#{value}"
      key = @keys[row]
      old = nil
      if col == 0
        oldkey = @keys[row]
        return if oldkey == value
        if !value.is_a?(oldkey.class) && do_type_conversion?
          value = TECode::Text.convert(oldkey.class, value)
        end
        @keys[row] = value
        @hash[value] = @hash[oldkey]
        @hash.delete(oldkey)
        old = oldkey
      else
        old = @hash[key]
        return if old == value
        if !value.is_a?(old.class) && do_type_conversion?
          value = TECode::Text.convert(old.class, value)
        end
        @hash[key] = value
      end
      self[row].row_edited = true if old != value
      fire_row_changed(row, self[row])
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
