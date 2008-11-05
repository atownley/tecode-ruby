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
# File:     standard_tableview.rb
# Author:   Andrew S. Townley
# Created:  Wed Nov  5 08:00:32 GMT 2008
#
######################################################################
#++

module TECode
module UI
module Gtk

  # This class provides a "standard" GtkTreeView configured as
  # a table (no tree functionality).

  class StandardTableView < Widget
    include SelectionNotifier

    def initialize(editable = false)
      super(init_view)
      self.editable = editable
    end

    def editable?
      @editable
    end

    def editable=(val, sentinal_row = true)
      @editable = val
    end

    def selection
      sel = Selection.new("text/plain", 
    ### Implement the table change observer interface ###
    
    def table_row_inserted(sender, index, object)
    end

    def table_row_deleted(sender, index, object)
    end

    def table_row_changed(sender, index, object)
    end
  end

end
end
end
