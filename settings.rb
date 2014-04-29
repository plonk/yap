# -*- coding: utf-8 -*-
require 'observer'
require_relative 'extensions'

class Settings_
  include Observable

  SETTINGS_DIR = ENV['HOME'] / ".yap"

  VARIABLES = %w[USER_PLAYER USER_PEERCAST].map(&:to_sym)

  def initialize
    super

    unless File.exist? SETTINGS_DIR
      puts "#{SETTINGS_DIR}を作りました。"
      Dir.mkdir(SETTINGS_DIR)
    end

    @variables = Hash.new
  end

  def [] sym
    raise "unknown variable name #{sym}" unless VARIABLES.include?(sym)
    @variables[sym]
  end

  def []= sym, value
    raise "unknown variable name #{sym}" unless VARIABLES.include?(sym)
    @variables[sym] = value
    changed
    notify_observers
    value
  end

  def load
    begin
      File.open(SETTINGS_DIR / "settings.txt", "r") do |f|
        f.each_line.map do |line|
          var, val = line.chomp.split(/ = /, 2)
          self[var.to_sym] = eval(val)
        end
      end
    rescue
      # do nothing
    end
    changed
    notify_observers
  end

  def save
    File.open(SETTINGS_DIR / "settings.txt", "w") do |f|
      @variables.each_pair do |var, val|
        f.puts "#{var.to_s} = #{val.inspect}" if @variables[var.to_sym] != nil
      end
    end
  end
end

Settings = Settings_.new
Settings.load
