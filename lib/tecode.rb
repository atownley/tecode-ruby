#--
######################################################################
#
# Copyright (c) 2008, Andrew S. Townley
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
# File:        tecode.rb
# Author:      Andrew S. Townley
# Created:     Sat Nov  1 08:58:55 GMT 2008
#
######################################################################
#++

require 'rubygems'

require 'tecode/object'
require 'tecode/data'
require 'tecode/time'
require 'tecode/trace'
require 'tecode/mime'
require 'tecode/mixin'
require 'tecode/host'
require 'tecode/io/ini'
require 'tecode/io/properties'
require 'tecode/shell'
require 'tecode/table/table_model'
require 'tecode/table/array_table_model'
require 'tecode/table/hash_table_model'
require 'tecode/table/object_table_model'
require 'tecode/text'
require 'tecode/thread/thread'
require 'tecode/thread/task'
require 'tecode/thread/event'
require 'tecode/ui/notification'
require 'tecode/ui/selection'
require 'tecode/ui/menu'
require 'tecode/ui/console/progress_monitor'
require 'tecode/xml'

module TECode
  # Formats the exception (I'm sure there's a way to do
  # this automatically...)

  def TECode.format_exception(e)
      "Exception in thread \"#{Thread.current}\" #{e.class}: #{e}\n\tfrom " << e.backtrace.join("\n\tfrom ")
  end
end
