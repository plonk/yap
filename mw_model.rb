# -*- coding: utf-8 -*-
require 'observer'
require_relative 'favorites'
require_relative 'launcher'
require_relative 'type_association'

# アプリケーションモデルとかプレゼンターとかそんなの。
class MainWindowModel
  include Observable

  # お気に入りオブジェクト。
  attr_reader :favorites

  # 通知テキスト。
  attr_reader :notification

  # 配信中の全てのチャンネル。
  attr_reader :master_table
  attr_reader :just_began
  # 終了チャンネル。
  attr_reader :finished

  # 検索中の言葉。
  attr_reader :search_term

  attr_reader :selected_channel
  
  # YP リスト
  attr_reader :yellow_pages

  def initialize
    super

    @favorites = Favorites.new
    @favorites.load
    @favorites.add_observer(self, :favorites_changed)
    @search_term = ""
    @notification = ""
    @master_table = []
    @update_first_time = true
    @yellow_pages = []

    add_yp YellowPage.new("SP",       "http://bayonet.ddo.jp/sp/", nil)
    add_yp YellowPage.new("TP",       "http://temp.orz.hm/yp/")
    add_yp YellowPage.new("event",    "http://eventyp.xrea.jp/", nil, nil)
    add_yp YellowPage.new("DP",       "http://dp.prgrssv.net/")
    add_yp YellowPage.new("multi-yp", "http://peercast.takami98.net/multi-yp/", nil, nil)
    add_yp YellowPage.new("アスチェ", "http://asuka--sen-nin.ddo.jp/checker/", nil, nil)
  end


  def total_channel_count
    master_table.size
  end

  def is_on_air?(name)
    @yellow_pages.any? do |yp|
      yp.any? { |ch| ch.name == name }
    end
  end

  def find_channel_by_hash(hash)
    @yellow_pages.each do |yp|
      yp.each_channel do |ch|
        return ch if ch.hash == hash
      end
    end
    nil
  end

  def get_channel(name)
    @yellow_pages.each do |yp|
      yp.each_channel do |ch|
        return ch if ch.name == name
      end
    end
    return nil
  end

  def get_channels(name)
    @yellow_pages.flat_map do |yp|
      ch = yp.get_channel(name)
      ch ? [ch] : []
    end
  end

  def add_yp(yp)
    @yellow_pages << yp
  end

  def show_channel_info ch
    if master_table.include? ch
      changed
      notify_observers(:show_channel_info, ch)
    end
  end

  def select_channel ch
    @selected_channel = ch
    changed
    notify_observers(:selected_channel_changed)
  end

  def toggle_favorite
    changed
    notify_observers(:favorite_toggled)
  end

  def play(channel)
    player = TypeAssociation.instance.launcher(channel.type)
    if player
      STDERR.puts "Launching #{player.interpolate(channel)}"
      player.spawn(channel)
    end
  end

  def notification=(text)
    @notification = text
    changed
    notify_observers :notification_changed
  end

  def favorites_changed
    changed
    notify_observers :favorites_changed
  end

  def search_term= term
    @search_term = term
    changed
    notify_observers :search_term_changed, term
  end

  def finalize
    @favorites.delete_observer(self)
    @favorites.save
    stop_helper_threads
  end

  def start_helper_threads
    start_reload_button_manager_thread
    start_updater_thread
  end

  def stop_helper_threads
    @reload_button_state_helper.kill
    @updater_thread.kill
  end

  def reload
    @reload_history.push Time.now
    Thread.new do 
      update_channel_list
    end
  end

  private 

  # チャンネル DB に追加・更新。
  def update_channel_db
    @yellow_pages.each do |yp|
      yp.each_channel do |ch|
        $CDB[ch.name] = [yp.timestamp.to_i, ch.contact_url].to_csv
      end
    end
    changed
    notify_observers(:channel_db_updated)
  end

  def spawn_yp_updater_threads
    threads = []
    @yellow_pages.each do |yp|
      threads << Thread.new do 
        unless yp.retrieve
          puts "Failed in retrieving from #{yp.name}"
        end
      end
    end
    threads
  end

  # 通知テキストを更新する。
  def update_notification
    if @update_first_time
      @update_first_time = false
    else
      self.notification = if @just_began.empty? 
                            "新着チャンネルはありません。"
                          else
                            @just_began.map(&:name)
                              .sort
                              .map { |name| favorites.include?(name) ? name+"★" : name }
                              .join("、") + " が配信を開始しています。"
                          end
    end
  end

  # チャンネルリストを取得する。
  def update_channel_list
    puts "Updating channels..."
    spawn_yp_updater_threads().each &:join
    puts "Done."

    new_table = @yellow_pages.map(&:to_a).inject(:+)
    @finished = @master_table - new_table
    @just_began = new_table - @master_table
    @master_table = new_table

    changed
    notify_observers(:channel_list_updated)

    update_notification

    # ついでにチャンネルDBを更新する。
    update_channel_db
  end

  # 更新ボタンの有効無効を管理するスレッドを開始する。
  def start_reload_button_manager_thread
    @reload_history = []

    @reload_button_state_helper = Thread.start do
      while true
        now = Time.now
        @reload_history.delete_if { |x| now - x > $MANUAL_UPDATE_INTERVAL } # delete older than 3 minutes
        if @reload_history.size < $MANUAL_UPDATE_COUNT
          changed
          notify_observers(:until_reload_toolbutton_available, 0)
        else
          i = (@reload_history[0] + $MANUAL_UPDATE_INTERVAL - Time.now).to_i
          changed
          notify_observers(:until_reload_toolbutton_available, i)
        end
        sleep 1
      end
    end
  end

  def start_updater_thread
    # 自動更新スレッド
    @updater_thread = Thread.start do
      loop do
        update_channel_list
        sleep UPDATE_INTERVAL_MINUTE * 60
      end
    end
  end
end

