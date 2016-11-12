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
# File:     file.rb
# Author:   Andrew S. Townley
# Created:  Thu  2 Sep 2010 23:41:35 IST
#
######################################################################
#++

class File
  # from http://www.ruby-forum.com/topic/140101

  def self.canonical_path(path)
    # Cheating to avoid starting with the relative path
    newpath = File.expand_path(path)
    while newpath.gsub!(%r{([^/]+)/\.\./?}) { |match|
        $1 == '..' ? match : ''
        } do end
    newpath.gsub(%r{/\./}, '/').sub(%r{/\.\z}, '/')
  end
end

