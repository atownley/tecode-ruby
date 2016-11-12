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
# File:     progress_monitor.rb
# Author:   Andrew S. Townley
# Created:  Sat Nov  1 09:55:18 GMT 2008
#
######################################################################
#++

module TECode
module UI

  class TextProgressWidget
    # Initialize the progress bar.  Optional parameters are:
    #
    # 1. The length (in characters) for the progress bar
    # 2. The initial starting value
    # 3. The token to use to indicate progress

    def initialize(*args)
      if args.length >= 1
        @size = args[0]
      else
        @size = 30
      end
      if args.length >= 2
        @value = args[1]
      else
        @value = 0
      end
      if args.length >= 3
        @tok = args[2]
      else
        @tok = '#'
      end
    end

    def set(value)
      @value = value
    end

    def set(pos, max)
      @value = (pos * 1.0 / max * 1.0) * 100
    end

    def to_s()
      pos = (@size * @value / 100).to_i
      s = "["
      s << @tok * pos
      s << ' ' * (@size - pos)
      s << '] (%3d%%)' % (@value)
      s << "\n" if pos == @size
      s
    end
  end

  class ProgressMonitor < TextProgressWidget
    def on_notification_event(sender, event)
      if event.is_a? TECode::Thread::TaskCompletionEvent
        if event.task != @task
          STDOUT.flush
          @task = event.task
        end
        set(event.current_pos, event.end_pos)
        if(event.task.name.length > 20)
          name = event.task.name[0..5] + "..." + event.task.name[-12..-1]
        else
          name = event.task.name + " " * (21 - event.task.name.length)
        end
        print "\r" + name + ": " + to_s
        STDOUT.flush
      end
    end
  end
end
end
