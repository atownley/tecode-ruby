#--
######################################################################
#
# Copyright (c) 2005-2008, Andrew S. Townley
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
# File:      thread.rb
# Created:   Mon Aug 29 22:04:43 IST 2005
# Author:    Andrew S. Townley
#
######################################################################
#++

require 'thread'
require 'timeout'

module TECode
module Thread

  # Hack to provide a name to the thread so we can see where
  # all of these critters are comming from.

  class NamedThread < ::Thread
    def initialize(name, *args)
      super(*args)
      @name = name
    end

    def to_s
      "#{@name}:#{super}"
    end

    def inspect
      "#{@name}:#{super}"
    end

    attr_accessor :name
  end

  # This class implements a thread pool of a fixed size.  Each
  # worker thread is "warm" in that they are re-used for other
  # execution objects.  Any object can be added to the pool to
  # be run, however it must have a #run method.  The Runnable
  # class provides a good, simple way to do this.

  class ThreadPool
    def initialize(size, name ="pool", logger = nil)
      @name = name
      @work = Queue.new
      @workers = []
      @group = ThreadGroup.new
      @shutdown = false
      @logger = logger
      @mutex = Mutex.new
      id = 0
      size.times do
        t = NamedThread.new("ThreadPool:#{@name}-worker:#{id}") { Thread.stop; thread_work };
        @workers << t
        @group.add(t)
        id += 1
      end
      @monitor = NamedThread.new("#{@name}-monitor") do
        Thread.stop
        loop do
          Thread.current.terminate if @shutdown
          sleep(1)
        end
      end
    end

    def <<(runnable)
      @work << runnable
      self
    end

    def start
      @workers.each { |w| w.run }
      @monitor.run
    end

    def join
      @monitor.join
    end

    def shutdown(wait = true, timeout = 20)
      @shutdown = true

      # ensure we wait for the monitor to stop as well,
      # otherwise you'll end up with a deadlock condition.
      if(wait)
        begin
          Timeout::timeout(timeout) do
            join
            @workers.each { |w| w.join if w.alive? }
          end
        rescue Timeout::Error
          # kill the threads
          warn("ThreadPool:#{@name} killing remaining threads...")
          begin
            @monitor.terminate if @monitor.alive?
            @workers.each { |w| w.terminate if w.alive? }
          rescue Exception => e
            warn("Ignoring exception:  " << Rubus::format_exception(e))
          end
        end
      end
    end
   
    def to_s
      "#<#{self.class}:#{@name} size=#{@workers.length}>"
    end

    def size
      @workers.length
    end

    def jobs
      @work.length
    end

  private
    
    def thread_work
      loop do
        if @shutdown
          puts "#{Thread.current} stopping";
          Thread.current.terminate
        end
        job = @work.deq 
        begin
          job.run if job != nil
          Thread.pass
        rescue => e
          error(Rubus::format_exception(e))
          next
        end
      end
    end
    
    def error(msg)
      if(@logger != nil)
        @logger.error(msg)
      else
        STDERR.puts "ERROR:  " << msg
        STDERR.flush
      end
    end

    def warn(msg)
      if(@logger != nil)
        @logger.warn(msg)
      else
        STDERR.puts "WARNING:  " << msg
        STDERR.flush
      end
    end

  end

  # This simple class is used in conjunction with the
  # ThreadPool class.  However, any class with a run method
  # can be used as well.  Any arguments passed to the
  # constructor are passed into the block during execution.

  class Runnable
    def initialize(*args, &block)
      @block = block
      @args = args
    end

    def run
      @block.call(*@args)
    end
  end

  # This is a simple extension of the normal Queue class to
  # add the timed deq method that doesn't play havoc with
  # multiple threads

  class TimedReadQueue < Queue
    
    # Waits for the specified timeout (seconds) and returns,
    # waking up the accessing thread.  This method avoids a
    # problem with using Timeout and Queue together to achieve
    # the same result.

    def tdeq(timeout)
      data = nil
      
      if(empty?)
        mt = Thread.current

        # This thread will wait for the timeout.  If it is still
        # alive, it will remove the read thread (rt) from the
        # waiting list, kill it and restart the main thread.

        rt = nil
        tt = NamedThread.new("timer") do
          Thread.stop; sleep(timeout); @waiting.delete(rt); mt.wakeup
        end
        
        # This thread will actually try and read the data.  If
        # it gets data, it will kill the timer and wake up the
        # main thread.

        rt = Thread.new("read") do
          Thread.stop; data = deq; __arnold(tt); mt.wakeup
        end

        begin
          tt.run
          rt.run
          Thread.stop
        ensure
          mt.wakeup
          __arnold(tt)
          __arnold(rt)
        end
      else
        # just read the data
        begin
          data = deq(true)
        rescue ThreadError => e
          puts Rubus.format_exception(e)
          # don't care
          data = nil
        end
      end

      # return the data value
      data
    end

  private

    # This method takes a thread and unconditionally terminates
    # it, completely and utterly

    def __arnold(thread)
      thread.kill if thread && thread.alive?
    end
  end
end
end
