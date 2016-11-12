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
# File:     task.rb
# Author:   Andrew S. Townley
# Created:  Fri Dec  2 19:49:06 GMT 2005
#
######################################################################
#++

module TECode
module Thread

  # This module provides event-based notifications to
  # registered observers.

  module NotificationSource
    def register_notification_listener(listener)
      listeners = (@notification_listeners ||= [])
      listeners << listener if !listeners.include? listener
    end

    def unregister_notifiaction_listener(listener)
      listeners = (@notification_listeners ||= [])
      listeners.delete(listener)
    end

  protected
    def fire_notify(event)
      listeners = (@notification_listeners ||= [])
      listeners.each do |listener|
        listener.on_notification_event(self, event)
      end
    end
  end
      
  # This class implements the GoF Command pattern and
  # represents a type of task that can be executed via a
  # common interface.  Each task must be given a name

  class Task < Runnable
    def initialize(name, *args, &block)
      super(*args, &block)
      @name = name
    end
   
    attr_reader :name
  end

  # This class provides an extension to the base task which
  # will support adding notification listeners which will
  # observe changes in the task.

  class MonitoredTask < Task
    include NotificationSource
  end

  # This class provides a compound, monitored task which will
  # report status completion as the child tasks complete.

  class CompoundTask < MonitoredTask
    def initialize(name, *args, &block)
      super
      @tasks = []
    end

    def add(task)
      @tasks << task
    end

    def remove(task)
      @tasks.remove(task)
    end

    def <<(task)
      @tasks << task
    end

    def run
      count = 0
      @tasks.each do |task|
        task.execute
        count = count + 1
        fire_notify(CompletionEvent.new(self, 1, @tasks.length, count))
      end
    end
  end
end
end
