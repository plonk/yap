# -*- coding: utf-8 -*-
require 'observer'
require_relative 'utility'

class Favorites
  include Enumerable
  include Observable

  FAVORITES_FILE = ENV['HOME'] / ".yap/favorites.txt"

  def initialize
    @list = []
  end

  def replace(ary)
    @list.replace(ary)
    changed
    notify_observers
  end

  def <<(item)
    raise unless item.is_a? String
    @list << item
    changed
    notify_observers
  end

  def each(&block)
    @list.each &block
  end

  def to_a
    @list.dup
  end

  def join(separator)
    @list.join(separator)
  end

  def touch path
    File.open path, "w" do end
  end

  def load
    # お気に入りチャンネルファイル
    touch FAVORITES_FILE unless File.exist? FAVORITES_FILE

    File.open(FAVORITES_FILE, "r:utf-8") do |fm|
      self.replace(fm.each_line.map(&:chomp))
    end
  end

  def save
    File.open(FAVORITES_FILE, "w") do |fm|
      fm.puts self.map { |chname| chname + "\n" }.join
    end
  end

  def delete(name)
    @list.delete(name)
    changed
    notify_observers
  end
end
