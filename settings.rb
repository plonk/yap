# -*- coding: utf-8 -*-
require 'singleton'
require 'observer'
require 'yaml'
require_relative 'extensions'

class Settings_
  include Singleton
  include Observable

  SETTINGS_DIR = ENV['HOME'] / ".yap"

  VARIABLES = %w[USER_PLAYER USER_PEERCAST TYPE_ASSOC].map(&:to_sym)

  def initialize
    super

    unless File.exist? SETTINGS_DIR
      puts "#{SETTINGS_DIR}を作りました。"
      Dir.mkdir(SETTINGS_DIR)
    end

    @variables = { :TYPE_ASSOC => [["WMV|FLV", "mplayer $Y"]] }
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
      data = YAML.load_file(SETTINGS_DIR / "settings.yml")
      @variables = @variables.merge Hash[*data.flat_map { |str, val| [str.to_sym, val] }]
    rescue Errno::ENOENT
      # do nothing
    end
    changed
    notify_observers
  end

  def save
    File.open(SETTINGS_DIR / "settings.yml", "w") do |f|
      data = Hash[*@variables.flat_map { |sym, val| [sym.to_s, val] }]
      f.write YAML.dump(data)
    end
  end
end

Settings = Settings_.instance
Settings.load
