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
# File:        host.rb
# Author:      Andrew S. Townley
# Created:     Mon Aug 22 19:01:26 IST 2005
#
######################################################################
#++

require 'socket'

module TECode

  # This class provides a unified way to get information about
  # the underlying operating system and host.

  class HostInfo
    attr_reader :name

    def initialize
      case RUBY_PLATFORM
      when /linux/
        @delegate = LinuxInfo.new
      else
        raise Exception, "no HostInfo delegate defined for platform '#{RUBY_PLATFORM}'"
      end

      @name = Socket.gethostname
    end

    def method_missing(method, *args, &block)
      @delegate.send(method, *args, &block)
    end
  end

  # This class extracts all of the information from the
  # various files in proc.

  class LinuxInfo
    def initialize
      # I realize I could get this in one go, but I don't want
      # to have to parse the -a line and guess.  Besides, it's
      # only run once...
      @hardware = `uname -p`.chomp  # might want to use -m/i...
      @os_name = `uname -s`.chomp
      @os_version = `uname -r`.chomp
      @os_release = `uname -v`.chomp

      line = nil
      File.open("/proc/meminfo") { |file| line = file.gets }

      @memory = line.chomp.split[1].to_i / 1024

      @num_cpus = 0
      File.open("/proc/cpuinfo") do |file|
        file.each_line do |line|
          case line
            when /^processor/
              @num_cpus += 1
            when /^cpu MHz/
              @cpu_speed = line.chomp.split(":")[1].strip
          end
        end
      end
    end

    attr_reader :hardware, :memory, :num_cpus, :cpu_speed
    attr_reader :os_name, :os_version, :os_release
  end
  
end
