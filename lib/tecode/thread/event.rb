#--
######################################################################
#
# Copyright 2005-2008, Andrew S. Townley
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
# File:     event.rb
# Author:   Andrew S. Townley
# Created:  Fri Dec  2 19:49:24 GMT 2005
#
######################################################################
#++

module TECode
module Thread

  class TaskStartEvent
    def initialize(task)
      @task = task
    end

    attr_reader :task
  end

  class TaskCompletedEvent
    def initialize(task)
      @task = task
    end

    attr_reader :task
  end
    
  # This class provides completion status information about a
  # monitored task.

  class TaskCompletionEvent
    
    # The event is fully initialized by the constructor with
    # the following parameters:
    #
    # task - the task generating the event
    # spos - the start position
    # cpos - the current position
    # epos - the end position

    def initialize(task, spos, cpos, epos)
      @task = task
      @start_pos = spos
      @end_pos = epos
      @current_pos = cpos
    end

    attr_reader :task
    attr_reader :start_pos
    attr_reader :end_pos
    attr_reader :current_pos
  end

  # This class provides message notifications for
  # informational messages.

  class InformationEvent
    def initialize(message)
      @message = message
    end

    def to_s
      @message
    end

    attr_reader :message
  end
end
end
