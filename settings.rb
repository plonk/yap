# -*- coding: utf-8 -*-
require 'observer'
require 'yaml'
require_relative 'extensions'
require_relative 'config'

# アプリケーション設定クラス
class SettingsClass
  include Observable

  def self.type_assoc_platform
    case RUBY_PLATFORM
    when /mingw/
      [['WMV', '"C:/Program Files/Windows Media Player/wmplayer.exe" $Y'],
       ['OPV', 'start "" $3']]
    else
      [['WMV|FLV', 'mplayer $Y'],
       ['OPV', 'xdg-open $3']]
    end
  end

  def self.list_font_platform
    (RUBY_PLATFORM =~ /mingw/) ? 'Meiryo 9' : 'Sans 10'
  end

  VARIABLES = {
    TYPE_ASSOC: type_assoc_platform,
    TOOLBAR_VISIBLE: true,
    CHANNEL_INFO_VISIBLE: true,
    YELLOW_PAGES:
    [
      [true, 'SP', 'http://bayonet.ddo.jp/sp/', nil, 'getgmt.php?cn='],
      [true, 'TP', 'http://temp.orz.hm/yp/', 'chat.php?cn=', 'getgmt.php?cn='],
      [true, 'event', 'http://eventyp.xrea.jp/', nil, nil],
      [true, 'DP', 'http://dp.prgrssv.net/', nil, nil],
      [true, 'multi-yp', 'http://peercast.takami98.net/multi-yp/', nil, nil],
      [true, 'アスカチェッカー', 'http://asuka--sen-nin.ddo.jp/checker/', nil, nil],
      [true, 'cavetube', 'http://rss.cavelis.net/', nil, nil]
    ],
    USER_PEERCAST: '127.0.0.1:7144',
    REVERSE_LOOKUP_TIP: true,
    NOTIFICATION_AUTO_CLOSE_SECONDS: 15,
    LIST_FONT: list_font_platform,
    ENABLE_AUTO_BANDWIDTH_CHECK: true,
    GRID_LINES: 1,
    RULES_HINT: true,
    COLUMN_PREFERENCE: [0, 1, 2, 3, 7, 4, 5, 6],
    ENABLE_VIEWLOG: false
  }

  VAR_NAMES = VARIABLES.keys

  def initialize(directory)
    @dir = directory

    make_sure_exists @dir

    @variables = VARIABLES
  end

  def make_sure_exists dir
    return if File.exist? dir

    puts "#{dir}を作りました。"
    Dir.mkdir(dir)
  end

  def [](sym)
    fail "unknown variable name #{sym}" unless VAR_NAMES.include?(sym)
    @variables[sym]
  end

  def []=(sym, value)
    fail "unknown variable name #{sym}" unless VAR_NAMES.include?(sym)
    @variables[sym] = value
    changed
    notify_observers
  end

  def settings_yaml_file
    @dir / 'settings.yml'
  end

  def load
    data = YAML.load_file(settings_yaml_file)
    from_file = Hash[*data.flat_map { |str, val| [str.to_sym, val] }]
    @variables = @variables.merge from_file
    changed
    notify_observers
  rescue Errno::ENOENT
    STDERR.puts "Warning: #{settings_yaml_file} not found"
  end

  def save
    File.open(@dir / 'settings.yml', 'w') do |f|
      data = Hash[*@variables.flat_map { |sym, val| [sym.to_s, val] }]
      f.write YAML.dump(data)
    end
  end
end

Settings = SettingsClass.new($SETTINGS_DIR)
Settings.load
