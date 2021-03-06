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
# File:        time.rb
# Author:      Andrew S. Townley
# Created:     Mon Aug 22 19:01:26 IST 2005
#
######################################################################
#++

#++
# Add a tstamp method to the Time class because it doesn't
# support sub-second values

class Time
  # Print the timestamp with the optional precision (default
  # is 100ms).  Minimum precision is 1ms

  def Time.tstamp(*args)
    prec = 4
    time = nil
    if args.length == 0
      time = Time.now
    else
      time = args[0]
    end

    if args.length == 2
      prec = args[1] + 1
      prec = 1 if prec < 1
    end

    if prec == 0
      sprintf("%04d-%02d-%02dT%02d:%02d:%02d", time.year,
                  time.month, time.day, time.hour, time.min, time.sec)
    else
      sprintf("%04d-%02d-%02dT%02d:%02d:%02d%s", time.year,
                  time.month, time.day, time.hour, time.min, time.sec,
                  (time.to_f - time.to_i).to_s[1..prec])
    end
  end

  # Ensure that the timstamp is UTC instead of local time

  def Time.tstampz(*args)
    if args.length == 0
      args << Time.now.getutc
    end
    "#{Time.tstamp(*args)}Z"
  end

  def tstamp(*args)
    Time.tstamp(self, *args)
  end

  def tstampz(*args)
    Time.tstampz(self.getutc, *args)
  end
end

module TECode
  
  # This class is used to track processing time for a
  # particular object.  

  class TimerDecorator
    attr_reader :created
    attr_reader :obj

    # This method is used to determine how long the object has
    # been timed.

    def elapsed
      Time.now - @created
    end

    def to_s
      "[TimerDecorator: created = #{@created}; elapsed = #{self.elapsed}; object=#{@obj}]"
    end

    # This method is used to wrap the object in an decorator
    # used to gather timing statistics.

    def initialize(obj = nil, &block)
      @created = Time.now
      @obj = obj
      if !block.nil?
        block.call
      end
    end

    # This method resets the time created for the object to
    # now.

    def reset
      @created = Time.now
    end

    def <=>(rhs)
      if rhs.is_a? TimerDecorator
#        puts "rhs: #{obj}: #{rhs.inspect}; #{self.created <=> rhs.created}"
        return self.created <=> rhs.created
      end
      super
    end

    def method_missing(method, *args, &block)
      @obj.send(method, *args, &block)
    end

  end

  SEC_IN_DAY  = 86400
  SEC_IN_HOUR = 3600

  # This method returns a hash containing the number of
  # days, hours and minutes of uptime.

  def self.calc_uptime(seconds)
    result = {}

    # I'm sure there's a better way, but it's 2AM...
    x = seconds / 60
    result["hours"] = (x / 60).to_i
    result["minutes"] = (x - (60 * result["hours"])).to_i
    result["days"] = (result["hours"] / 24).to_i
    result["hours"] = (result["hours"] - (24 * result["days"])).to_i
    result["seconds"] = seconds - (SEC_IN_DAY*result["days"] +
          SEC_IN_HOUR*result["hours"] + 60*result["minutes"])

    result
  end
 
  def self.format_uptime(seconds)
    return "0s" if seconds == 0

    ut = calc_uptime(seconds)
    s = ""
    s << "%dd" % ut["days"] if ut["days"] > 0
    s << "%dh" % ut["hours"] if ut["hours"] > 0
    s << "%dm" % ut["minutes"] if ut["minutes"] > 0
    s << "%0.5fs" % ut["seconds"]
  end

  class TimingContext < TimerDecorator
    def to_s
      "%0.5f" % elapsed
    end

    def started
      "Task #{obj} started at #{@created}"
    end

    def status
      "Task #{obj} running for #{self}"
    end

    def completed
      "Task #{obj} completed in #{self}"
    end  

    def puts(msg)
      STDOUT.puts "Task #{obj} at #{self}: #{msg}"
    end
  end

  def self.time(desc, verbose = false, &block)
    return if block.nil?
    tc = TimingContext.new(desc)
    puts tc.started if verbose
    rval = block.call(tc)
    puts tc.completed if verbose
    rval
  end

end
