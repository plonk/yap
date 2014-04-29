# -*- coding: utf-8 -*-
require 'observer'
require_relative 'favorites'
require_relative 'launcher'

class MainWindowModel
  include Observable

  attr_reader :favorites
  attr_reader :notification
  attr_reader :master_table
  attr_reader :just_began, :finished

  def initialize
    super

    @favorites = Favorites.new
    @favorites.load
    @favorites.add_observer(self, :favorites_changed)
    @search_term = ""
    @notification = ""
    @master_table = []
    @update_first_time = true
  end

  def toggle_favorite
    changed
    notify_observers(:favorite_toggled)
  end

  def play(channel)
    player = Launcher.new("mplayer $Y")
    STDERR.puts "Launching #{player.interpolate(channel)}"
    player.spawn(channel)
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

  attr_reader :search_term

  def finalize
    @favorites.delete_observer(self)
    @favorites.save
    @reload_button_state_helper.kill
    @updater_thread.kill
  end

  def start_helper_threads
    start_reload_button_manager_thread
    start_updater_thread
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

  # チャンネルリストを取得する
  def update_channel_list
    puts "Updating channels..."
    threads = []
    YellowPage.all.each do |yp|
      threads << Thread.new do 
        unless yp.retrieve
          puts "Failed in retrieving from #{yp.name}"
        end
      end
    end
    # wait for all the threads to finish
    threads.each &:join
    puts "Done."

    new_table = YellowPage.all.map(&:to_a).inject(:+)
    @finished = @master_table - new_table
    @just_began = new_table - @master_table
    @master_table = new_table

    # 通知を表示する。ここのロジックはモデルへ移動するべき。
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

    changed
    notify_observers(:channel_list_updated)

    # ついでにチャンネルDBを更新する。
    update_channel_db
  end


  def update_channel_db
    # channel DB に追加あるいは DB のエントリーを更新
    YellowPage.all.each do |yp|
      yp.each_channel do |ch|
        $CDB[ch.name] = [yp.timestamp.to_i, ch.contact_url].to_csv
      end
    end
    changed
    notify_observers(:channel_db_updated)
  end

  def reload
    @reload_history.push Time.now
    Thread.new do 
      update_channel_list
    end
  end

  private 
  def start_reload_button_manager_thread
    @reload_history = []

    # 更新ボタンの有効無効を管理するスレッド
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
end
