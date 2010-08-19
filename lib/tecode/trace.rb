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
  @@__trace_tracers = {}
  @@__trace_level = 0
  @@__trace_file = STDERR
  @@__trace_file_mutex = Mutex.new

  def self.included(base)
    Trace.__trace_instance(base)

    # define the maturity class methods
    base.instance_eval <<-EOS
      def self.trace_maturity
        Trace.__trace_instance("#{base}").maturity
      end

      def self.trace_maturity=(val)
        Trace.__trace_instance("#{base}").maturity = val
      end
    EOS
  end

  def self.__trace_instance(klass = self.class)
    class_name = klass.to_s
    tracer = @@__trace_tracers[class_name]
    if tracer.nil?
#      puts "Create new tracer for #{class_name}"
      tracer = Tracer.new(class_name)
      @@__trace_tracers[class_name] = tracer
    end
    tracer
  end

  def self.set_trace_maturity(klass, val)
    Trace.__trace_instance(klass).maturity = val
  end

  def self.level=(val)
    @@__trace_level = val
  end

  def self.level
    @@__trace_level
  end

  def self.file=(file)
    @@__trace_file_mutex.synchronize do
      if @@__trace_file != STDERR
        @@__trace_file.flush
        @@__trace_file.close
      end

      @@__trace_file = file
    end
  end

  def self.will_trace?(level)
    Trace.level >= level
  end
  
  def self.tputs(threshold, trace_name, *args)
    return if !Trace.will_trace?(threshold)

    @@__trace_file_mutex.synchronize do
      now = Time.now
      @@__trace_file.print now.strftime("%H:%M:%S") << ".%03d " % (now.usec)
      @@__trace_file.print "#{trace_name}"
      @@__trace_file.print "[#{::Thread.current}]" if ::Thread.current != ::Thread.main
      @@__trace_file.print " "
      @@__trace_file.puts(*args)
      @@__trace_file.flush
    end
  end

  # This method allows much more rubyish tracing of everything
  # within the block.  However, because the block given is not
  # a real lambda function, any use of return within the
  # block will prevent the return clause

  def trace(level, *args, &block)
    t = Trace.__trace_instance(self.class)
    if t.will_trace? level
      method = args.shift
      t.reset_clock
      returned = false
      begin
        if args.length == 0
          t.trace_start(method)
        else
          t.trace_start_with_args(method, *args)
        end
        rc = block.call(t)
        returned = true
        return t.trace_return(method, rc)
      rescue => e
        returned = true
        raise t.trace_throw(method, e)
      ensure
        if !returned
          t.tputs(1, "*** warning:  detected return inside trace block for '#{method}'!")
        end
        t.trace_end(method)
      end
    else
      return block.call(t)
    end
  end

  def mtrace(*args, &block)
    # this approach was taken from
    # http://www.ruby-forum.com/topic/75258
    args.insert 0, (caller[0] =~ /`([^']*)'/ and $1)
    trace(1, *args, &block)
  end

  def tputs(threshold, *args)
#    @@__tracer.tputs(threshold, *args)
    Trace.__trace_instance(self.class).tputs(threshold, *args)
  end

  def will_trace?(threshold)
    Trace.__trace_instance(self.class).will_trace? threshold
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

class Tracer
  def initialize(trace_name, maturity = 0)
    @trace_name = trace_name
    @maturity = maturity
    @started = Time.now
  end

  def reset_clock
    @started = Time.now
  end

  def elapsed
    Time.now - @started
  end

  def elapsed_s
    "%0.5f" % (elapsed)
  end

  def tputs(threshold, *args)
    return if !will_trace?(threshold)

    Trace.tputs(threshold, @trace_name, *args)
  end
  
  def will_trace?(threshold)
    thresh = (@maturity * 10) + threshold
#    puts "maturity: #{@maturity}; thresh: #{thresh}; will trace? #{Trace.level >= thresh}"
    Trace.level >= thresh
  end

  def trace_start(method, msg = "")
    return if !will_trace? 1
    tputs 1, "method call :#{method}(#{msg})"
  end

  def trace_start_with_args(method, *args)
    return if !will_trace? 1
    tputs 1, "method call: #{method}( " << format_arr(args) << " )"
  end

  def trace_return(method, *args)
    return *args if !will_trace? 1
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
    return if !will_trace? 1
    s = "" << " (elapsed: " << "%0.5f" % (elapsed) << ")"
    tputs 1, "method :#{method} end#{s}"
  end

  def maturity=(val)
#    puts "maturity for #{@trace_name} set to: #{val}"
    @maturity = val
  end

  def maturity
    @maturity
  end

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
#      if obj.length > 10
#        s << "[ " << "Array of size = #{obj.length}; " <<  format_arr(obj[0..9]) << ", ... ]"
        s << "[ " << "Array of size = #{obj.length} ]"
#      else
#        s << "[ " << format_arr(obj) << " ]"
#      end
    elsif obj.is_a? Hash
      if obj.size > 10
        s << " Hash of size = #{obj.size}; Key preview: [ " << format_arr(obj.keys[0..9]) << ", ... ]"
      else
        s << "#{obj.inspect}"  << " (#{obj.class})"
      end
    else
      s << "#{obj}"  << " (#{obj.class})"
    end
    s 
  end
end

end
