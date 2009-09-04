#--
######################################################################
#
# Copyright (c) 2005, Andrew S. Townley
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
# File:        trace.rb
# Author:      Andrew S. Townley
# Created:     Sun Aug 21 15:53:55 IST 2005
#
######################################################################
#++

require 'thread'

module TECode
module Trace
  @@tracers = {}
  @@level = 0
  @@file = STDERR
  @@file_mutex = Mutex.new

  def Trace.extend_object(obj)
    super(obj)
    obj.__send__(:__trace_initialize, obj.class)
  end

  def Trace.level=(level)
    @@level = level
  end

  def Trace.level
    @@level
  end

  def Trace.file=(file)
    @@file_mutex.synchronize do
      if @@file != STDERR
        @@file.close
      end

      @@file = file
    end
  end

  # Any arguments to be passed to parent classes must follow
  # the ident (default: object_id) and maturity (default: 0)
  # values

  def initialize(ident = self.object_id, maturity = 0, *args)
    super(*args)
    __trace_initialize(self.class, maturity, ident)
  end

  def __trace_initialize(name, maturity = 0, ident = self.object_id)
    @@tracers[name] = self
    @trace_name, @maturity = name, maturity
    @trace_id = ident
  end

  def tputs(threshold, *args)
    if not (will_trace? threshold)
      return
    end

    @@file_mutex.synchronize do
      now = Time.now
      @@file.print now.strftime("%H:%M:%S") << ".%03d " % (now.usec)
      @@file.print "#{@trace_name}[#{@trace_id}"
      @@file.print ":#{::Thread.current}" if ::Thread.current != ::Thread.main
      @@file.print "] "
      @@file.puts(*args)
      @@file.flush
    end
  end

  def will_trace?(threshold)
    return false if @maturity.nil?
    thresh = (@maturity * 10) + threshold
    if @@level >= thresh
      return true
    end

    return false
  end

  def trace_start(method, msg = "")
    if not (will_trace? 1)
      return
    end
    tputs 1, "method call :#{method}(#{msg})"
  end

  def trace_start_with_args(method, *args)
    if not (will_trace? 1)
      return
    end
    tputs 1, "method call: #{method}(" << format_arr(args) << ")"
  end

  def trace_return(method, *args)
    if not (will_trace? 1)
      return *args
    end
    s = "method :#{method} returning"
    if args.length > 0 
      s << ": #{format_arr(args)}"
    end

    tputs 1, s
    return *args
  end

  def trace_throw(method, klass, *args)
    ex = nil
    if args.length == 0
      ex = klass
      klass = ex.class
    else
      ex = klass.new(*args)
    end
    tputs 1, "method :#{method} throwing exception #{klass} with message: #{ex.message}"
    return ex
  end

  def trace_end(method)
    if not (will_trace? 1)
      return
    end
    tputs 1, "method :#{method} end"
  end

  attr_accessor :maturity
  attr_accessor :trace_id

private
  def format_arr(args)
    s = ""
    args.each do |a|
      s << format_obj(a)
      s << ", " if a != args[-1]
    end
    s
  end

  def format_obj(obj)
    s = ""
    if obj.nil?
      s << "(nil)"
    elsif obj.respond_to? :to_trace_str
      s << obj.to_trace_str 
    elsif obj.is_a? String
      s << "\"#{obj}\""
    elsif obj.is_a? Array
      s << "[ " << format_arr(obj) << " ]"
    else
      s << "#{obj}"  << " (#{obj.class})"
    end
    s 
  end
end

class MethodTrace
  def initialize(traced, method)
    @traced = traced
    @method = method
  end

  def start
    @traced.trace_start(@method)
  end

  def start_with_args(*args)
    @traced.trace_start_with_args(@method, *args)
  end

  def return(*args)
    @traced.trace_return(@method, *args)
  end

  def throw(*args)
    @traced.trace_throw(@method, *args)
  end

  def end
    @traced.trace_end(@method)
  end
end

end
