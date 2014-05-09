# -*- coding: utf-8 -*-
require 'monitor'

class ThreadSafeQueue
  class EmptyQueueException < StandardError
  end

  def initialize
    @data = Array.new
    @monitor = Monitor.new
  end

  def enq item
    @monitor.synchronize do
      @data.push item
    end
  end

  alias :<< :enq

  def deq
    @monitor.synchronize do
      if @data.empty?
        raise EmptyQueueException, "empty queue"
      else
        @data.shift
      end
    end
  end

  def size
    @monitor.synchronize do
      @data.size
    end
  end
end

module Gtk
  class << Gtk
    alias_method :old_main, :main
    alias_method :old_main_quit, :main_quit
  end

  @queue = ThreadSafeQueue.new

  # 30fps
  def self.main(timeout_milliseconds = 33)
    timeout_add timeout_milliseconds do
      begin
        block = @queue.deq
        block.call
      rescue ThreadSafeQueue::EmptyQueueException
        # wait for next tick
      end
      true # continue
    end
    old_main
  end

  # Gtk.queue: キューに処理を追加する。サブスレッドが Gtk の機能を使うと
  # きは必ず使う。
  def self.queue &block
    @queue << block
  end

  def self.main_quit
    if @queue.size != 0
      STDERR.puts "Warning: queue is not empty"
    end
    old_main_quit
  end
end
