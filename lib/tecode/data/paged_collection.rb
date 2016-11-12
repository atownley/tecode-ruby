#--
######################################################################
#
# Copyright (c) 2005-2016, Andrew S. Townley
# All rights reserved.
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
# File:        paged_collection.rb
# Author:      Andrew S. Townley
# Created:     Sat Nov 14 14:58:43 GMT 2009
#
######################################################################
#++

require 'thread'

module TECode
module Data
  
  # This class allows multi-session views of a collection in
  # terms of "pages" of information.  Any object that responds
  # to the [] operator and the size operator can be used as
  # the collection.

  class PagedCollection < SharedCollection
    def new_session(pagesize = 20)
      pagesize = 20 if pagesize.nil?
      manage_session(PageSession.new(self, pagesize))
    end
  end

  # This class represents a specific session (or cursor)
  # within the given PagedCollection instance

  class PageSession < CollectionSession
    attr_reader :page_size, :page

    def initialize(pc, page_size)
      super(pc)
      @index = -1
      @page = 1
      @page_size = page_size
    end

    # This method resets the page size for this session.
    
    def page_size=(val)
      raise InvalidSessionError, "Collection session has been invalidated" if !valid?
      @page_size = val
      if @page <= pages
        go_to(@page)
      else
        go_to(1)
      end
    end

    # This method will call the specified block for each item
    # in the collection in the "next" page

    def each_page_next(&block)
      raise InvalidSessionError, "Collection session has been invalidated" if !valid?
      return if @page > pages
      go_to(@page += 1)
      each_row(&block)
    end

    # This method will call the specified block for each item
    # in the collection in the "previous" page

    def each_page_prev(&block)
      raise InvalidSessionError, "Collection session has been invalidated" if !valid?
      #puts "Page: #{@page}; index = #{@index}"
      return if @page < 2
      go_to(@page -= 1)
      each_row(&block)
    end

    # This method will iterate over the current page

    def each(&block)
      raise InvalidSessionError, "Collection session has been invalidated" if !valid?
      go_to(@page)
      each_row(&block)
    end

    # This method returns the number of the current page.  It
    # is equivalent to the page method.
    
    def number
      raise InvalidSessionError, "Collection session has been invalidated" if !valid?
      page
    end

    def first
      raise InvalidSessionError, "Collection session has been invalidated" if !valid?
      @page = 1
    end

    def last
      raise InvalidSessionError, "Collection session has been invalidated" if !valid?
      @page = pages
    end

    def page=(val)
      raise InvalidSessionError, "Collection session has been invalidated" if !valid?
      go_to(val)
    end

    def go_to(page)
      raise ArgumentError, "Page cannot be nil!" if page.nil?
      raise InvalidSessionError, "Collection session has been invalidated" if !valid?
      if page < 0
        page = pages + page + 1
      elsif page == 0
        page = 1
      end
      @page = page 
      
      @index = (@page - 1) * page_size

    end

    # This method will return the current number of pages
    # possible given the current page size.

    def pages
      raise InvalidSessionError, "Collection session has been invalidated" if !valid?

      _pages = size / page_size
      if size % page_size > 0
        _pages += 1
      end
      _pages
    end

    alias :count :pages

  private
    def each_row(&block)
      raise InvalidSessionError, "Collection session has been invalidated" if !valid?
      return if @page > pages

      1.upto(page_size) do |row|
        raise InvalidSessionError, "Collection session has been invalidated" if !valid?
        break if @index == @collection.size
        block.call(@index, row, @collection[@index])
        @index += 1
      end
    end
  end

end
end
