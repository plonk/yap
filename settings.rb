# -*- coding: utf-8 -*-
require 'singleton'
require 'observer'
require 'yaml'
require_relative 'extensions'

class Settings_
  include Singleton, Observable

  SETTINGS_DIR = ENV['HOME'] / ".yap"

  VARIABLES = {
    TYPE_ASSOC: [["WMV|FLV", "mplayer $Y"],
                    ["OPV", "xdg-open $3"]],
    TOOLBAR_VISIBLE: true,
    CHANNEL_INFO_VISIBLE: true,
    YELLOW_PAGES:
    [
     [true, "SP", "http://bayonet.ddo.jp/sp/", nil, "getgmt.php?cn="],
     [true, "TP", "http://temp.orz.hm/yp/", "chat.php?cn=", "getgmt.php?cn="],
     [true, "event", "http://eventyp.xrea.jp/", nil, nil],
     [true, "DP", "http://dp.prgrssv.net/", nil, nil],
     [true, "multi-yp", "http://peercast.takami98.net/multi-yp/", nil, nil],
     [true, "アスカチェッカー", "http://asuka--sen-nin.ddo.jp/checker/", nil, nil],
     [true, "cavetube", "http://rss.cavelis.net/", nil, nil],
    ],
    USER_PEERCAST: "127.0.0.1:7144",
    REVERSE_LOOKUP_TIP: true,
    NOTIFICATION_AUTO_CLOSE_SECONDS: 15,
    LIST_FONT: 'Sans 12',
    ENABLE_AUTO_BANDWIDTH_CHECK: true,
    GRID_LINES: 1,
    RULES_HINT: true,
  }

  VAR_NAMES = VARIABLES.keys

  def initialize
    super

    unless File.exist? SETTINGS_DIR
      puts "#{SETTINGS_DIR}を作りました。"
      Dir.mkdir(SETTINGS_DIR)
    end

    @variables = VARIABLES
  end

  def [] sym
    raise "unknown variable name #{sym}" unless VAR_NAMES.include?(sym)
    @variables[sym]
  end

  def []= sym, value
    raise "unknown variable name #{sym}" unless VAR_NAMES.include?(sym)
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
