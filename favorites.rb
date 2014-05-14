# -*- coding: utf-8 -*-
require 'observer'
require_relative 'utility'

class Favorites
  include Enumerable, Observable

  FAVORITES_FILE = ENV['HOME'] / '.yap/favorites.txt'

  def initialize
    @list = []
  end

  def set_equal?(a, b)
    (a & b).size == a.size
  end

  def replace(ary)
    if set_equal? ary, @list
      @list.replace(ary)
    else
      @list.replace(ary)
      changed
      notify_observers
    end
  end

  def <<(item)
    fail unless item.is_a? String
    unless @list.include? item
      @list << item
      changed
      notify_observers
    end
  end

  def each(&block)
    @list.each(&block)
  end

  def to_a
    @list.dup
  end

  def join(separator)
    @list.join(separator)
  end

  def touch(path)
    File.open(path, 'w').close
  end

  def load
    # お気に入りチャンネルファイル
    touch FAVORITES_FILE unless File.exist? FAVORITES_FILE

    File.open(FAVORITES_FILE, 'r:utf-8') do |fm|
      replace(fm.each_line.map(&:chomp))
    end
    changed
    notify_observers
  end

  def save
    File.open(FAVORITES_FILE, 'w') do |fm|
      fm.print map { |chname| chname + "\n" }.join
    end
  end

  def delete(name)
    if @list.include? name
      @list.delete(name)
      changed
      notify_observers
    end
  end
end
