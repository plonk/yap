#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

class Wakachi
  def initialize
    @pipe = IO.popen("chasen -F '%m '", "r+")
  end

  def self.open
    if block_given?
      w = Wakachi.new
      yield(w)
      w.close
    else
      Wakachi.new
    end
  end

  def jwords(str)
    @pipe.puts(str)
    @pipe.gets.strip.split
  end

  def close
    @pipe.close
  end
end

WAKACHI_INSTANCE = Wakachi.new

class String
  def jwords
    WAKACHI_INSTANCE.jwords(self)
  end
end

at_exit do
  WAKACHI_INSTANCE.close
end

if __FILE__ == $0
  p "庭には二羽鶏が居る。".jwords
  p "このファイルがあるフォルダーをファイルマネージャーで表示します。".jwords
end
