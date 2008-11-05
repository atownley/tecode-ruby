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
# File:     menu.rb
# Author:   Andrew S. Townley
# Created:  Wed Nov  5 14:53:02 GMT 2008
#
######################################################################
#++

module TECode
module UI

  module ContextMenuDelegator
    attr_accessor :context_menu_delegate

  protected
    def get_object_context_menu_items(selection)
      return nil if @context_menu_delegate.nil?
      @context_menu_delegate.get_object_context_menu_items(self, selection)
    end

    def get_non_object_context_menu_items
      return nil if @context_menu_delegate.nil?
      @context_menu_delegate.get_non_object_context_menu_items(self)
    end
  end

end
end
