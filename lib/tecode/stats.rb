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
# File:        stats.rb
# Author:      Andrew S. Townley
# Created:     Thu Aug 18 17:18:03 IST 2005
#
######################################################################
#++

module TECode::Stats
  # This class represents a set of basic statistics about a
  # monitored event.  It tracks the number of observations and
  # the times associated with the observations.

  class Timings
    def initialize
      @total_time = 0.0
      @min_time = 0.0
      @max_time = 0.0
      @obs_count = 0
      @mutex = Mutex.new
    end

    def record_time(tic)
      next if !tic
      @mutex.synchronize do
        @total_time = @total_time + tic
        @min_time = (tic < @min_time ? tic : @min_time)
        @max_time = (tic > @max_time ? tic : @max_time)
        @obs_count += 1
      end
    end

    def avg_time
      if obs_count > 0
        @total_time / @obs_count
      else
        0
      end
    end

    def to_s
      s = "[Timings: obs_count = #{@obs_count}; "
      s << "min_time = #{@min_time}; avg_time = #{avg_time}; "
      s << "max_time = #{@max_time}; total_time = #{@total_time}]"
    end
    
    def to_str
      to_s
    end

    attr_reader :total_time
    attr_reader :min_time
    attr_reader :max_time
    attr_reader :obs_count
  end

  class MonitoredEvent < Timings
    attr_reader :event
    
    def initialize(event)
      super()
      @event = event
    end

    def to_s
      s = "#{event} stats: count: #{obs_count}"
      s << "; min: " << TECode.format_uptime(min_time)
      s << "; max: " << TECode.format_uptime(max_time)
      s << "; avg: " << TECode.format_uptime(avg_time)
      s << "; total: " << TECode.format_uptime(total_time)
    end

    def to_str
      to_s
    end

    def to_csv
      s = "#{event.dump}, #{obs_count}, "
      s << "#{min_time}, #{max_time}, "
      s << "#{avg_time}, #{total_time}"
    end

    def observe(&block)
      timer = TECode::TimerDecorator.new(self)
      rval = block.call(timer) if block
      record_time(timer.elapsed)
      rval
    end
  end

  # This class allows you to monitor a set of related events
  # and easily manage them.

  class MonitorGroup
    attr_reader :ident

    def initialize(ident = nil)
      @stats = {}
      @counters = {}
      @ident = ident
    end

    def observe(event, &block)
      raise ArgumentError, "no event specified" if event.nil?
      raise ArgumentError, "no block specified" if block.nil?
      monitor = (@stats[event] ||= MonitoredEvent.new(event))
      monitor.observe(&block)
    end

    def count(event)
      count = (@counters[event] ||= 0)
      count += 1
      @counters[event] = count
    end

    def method_missing(method, *args, &block)
      @stats.send(method, *args, &block)
    end

    def to_s
      s = "Usage statistics"
      if @ident
        s << " for #{ident}: "
      else
        s << ": "
      end

      arr = [ s ]
      @counters.keys.sort.each do |key|
        arr << "#{key}: #{@counters[key]}"
      end
      arr << "--" if @counters.size > 0

      @stats.keys.sort.each do |key|
        arr << @stats[key].to_s
      end

      arr.join("\n")
    end

    def to_csv
      s = "Usage statistics"
      if @ident
        s << " for #{ident}: "
      else
        s << ": "
      end
      arr = [ s ]
      arr << "Key, Count, Min Time, Max Time, AVG Time, Total Time"
      @counters.keys.sort.each do |key|
        arr << "#{key.dump}, #{@counters[key]}"
      end
      arr << "--" if @counters.size > 0

      @stats.keys.sort.each do |key|
        arr << @stats[key].to_csv
      end

      arr.join("\n")
    end

    def to_str
      to_s
    end
  end
end
