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
# File:     shell.rb
# Created:	Thu  5 Aug 2010 07:03:24 IST
#
#####################################################################
#++

require 'open3'

module TECode

  class ShellCommand
    attr_reader :command, :args, :stdin, :stdout, :stderr, :proc

    def initialize(args, stdin, stdout, stderr, proc)
      @command = args[0]
      @args = args[1..-1]
      @stdin = stdin
      @stdout = stdout
      @stderr = stderr
      @proc = proc
    end

    def exited?
      @proc.exited?
    end

    def success?
      @proc.exited? && @proc.success?
    end

    def exit_status
      @proc.exitstatus
    end

    def self.execute(*args, &block)
      stdin, stdout, stderr = Open3.popen3(*args, &block)
      ShellCommand.new(args, stdin, stdout, stderr, $?)
    end
  end

end
