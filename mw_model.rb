# -*- coding: utf-8 -*-
require 'observer'
require_relative 'favorites'
require_relative 'launcher'
require_relative 'type_association'
require_relative 'child_process'
require_relative 'peercast_health'

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

  attr_reader :selected_channel

  # YP リスト
  attr_reader :yellow_pages

  attr_reader :child_processes

  UPDATE_INTERVAL_MINUTE = 10
  MANUAL_UPDATE_INTERVAL = 5 * 60
  MANUAL_UPDATE_COUNT = 5

  def initialize
    super

    @favorites = Favorites.new
    @favorites.load
    @favorites.add_observer(self, :favorites_changed)

    Settings.add_observer(self, :settings_changed)

    @notification = ''
    @master_table = []
    @update_first_time = true
    @child_processes = []

    @yellow_pages = active_yellow_pages
  end

  def active_yellow_pages
    Settings[:YELLOW_PAGES].to_enum
      .select { |enabled, | enabled }
      .map do |_enabled, name, url, chat_path, stat_path|
      YellowPage.get(name, url, chat_path, stat_path)
    end
  end

  def settings_changed
    unless @yellow_pages.set_equal? active_yellow_pages
      @yellow_pages = active_yellow_pages
      do_update_channel_list(false, false)
    end
    changed
    notify_observers(:settings_changed)
  end

  def child_process_changed
    changed
    notify_observers(:child_process_changed)
  end

  def total_channel_count
    master_table.size
  end

  def find_channel_by_channel_id(chid)
    @yellow_pages.each do |yp|
      yp.each_channel do |ch|
        return ch if ch.channel_id == chid
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
    nil
  end

  def get_channels(name)
    @yellow_pages.flat_map do |yp|
      ch = yp.get_channel(name)
      ch ? [ch] : []
    end
  end

  def show_channel_info(ch)
    if master_table.include? ch
      changed
      notify_observers(:show_channel_info, ch)
    end
  end

  def select_channel(ch)
    STDERR.puts "#{ch} selected in mw_model"
    @selected_channel = ch
    changed
    notify_observers(:selected_channel_changed)
  end

  def toggle_favorite
    if favorites.include? selected_channel.name
      favorites.delete(selected_channel.name)
    else
      favorites << selected_channel.name
    end
  end

  def acknowledge_child(child)
    child.add_observer(self, :child_process_changed)
    @child_processes << child
    changed
    notify_observers(:child_process_changed)
  end

  def play(channel)
    channel.train(:ham)
    changed
    notify_observers(:channel_list_updated)
    do_play(channel)
  end

  def do_play(channel)
    player = TypeAssociation.instance.launcher(channel.type)
    if player
      STDERR.puts "Launching #{player.interpolate(channel)}"
      acknowledge_child player.spawn(channel)
    end
  rescue StandardError => e
    self.notification = "エラー: #{e.message}"
  end

  def clear_finished_child_processes
    @child_processes.select(&:finished?).each do |cp|
      cp.delete_observer(self)
      @child_processes.delete(cp)
    end
    changed
    notify_observers(:child_process_changed)
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

  def finalize
    Channel.save_classifier_state

    @favorites.delete_observer(self)
    @favorites.save

    Settings.delete_observer(self)
    Settings.save

    stop_helper_threads
  end

  def start_helper_threads
    start_reload_button_manager_thread
    start_updater_thread
    start_peercast_watcher_thread
  end

  def stop_helper_threads
    @reload_button_state_helper.kill
    @updater_thread.kill
    @peercast_watcher_thread.kill
  end

  def reload
    @reload_history.push Time.now
    Thread.new do
      update_channel_list
    end
  end

  # チャンネルリストを取得する。
  def update_channel_list
    do_update_channel_list(true, true)
  end

  def spawn_yp_updater_threads
    puts 'Updating channels...'
    threads = []
    @yellow_pages.each do |yp|
      threads << Thread.new do
        success = yp.retrieve
        puts "Failed in retrieving from #{yp.name}" unless success
      end
    end
    puts 'Done.'
    threads
  end

  # 通知テキストを更新する。
  def update_notification
    return @update_first_time = false if @update_first_time

    self.notification = notification_text
  end

  def notification_text
    if @just_began.empty?
      '新着チャンネルはありません。'
    else
      @just_began.map(&:name)
        .sort
        .map { |name| favorites.include?(name) ? name + '★' : name }
        .join('、') + ' が配信を開始しています。'
    end
  end

  def ascertain_yellow_pages_loaded
    @yellow_pages.each do |yp|
      yp.retrieve unless yp.loaded?
    end
  end

  def update_tables
    new_table = @yellow_pages.flat_map(&:to_a)
    @finished = @master_table - new_table
    @just_began = new_table - @master_table
    @master_table = new_table
    changed
    notify_observers(:channel_list_updated)
  end

  def do_update_channel_list(full_update, notify)
    if full_update
      spawn_yp_updater_threads.each(&:join)
    else
      ascertain_yellow_pages_loaded
    end

    update_tables

    update_notification if notify
  end

  # 更新ボタンの有効無効を管理するスレッドを開始する。
  def start_reload_button_manager_thread
    @reload_history = []

    @reload_button_state_helper =
      Thread.start(&method(:reload_button_manager_thread))
  end

  def delete_old_reload_history
    @reload_history.delete_if { |x| Time.now - x > MANUAL_UPDATE_INTERVAL }
  end

  def time_until_user_can_reload
    if @reload_history.size < MANUAL_UPDATE_COUNT
      0
    else
      (@reload_history[0] + MANUAL_UPDATE_INTERVAL - Time.now).ceil
    end
  end

  def reload_button_manager_thread
    every_nseconds 1 do
      delete_old_reload_history
      changed
      notify_observers(:until_reload_toolbutton_available,
                       time_until_user_can_reload)
    end
  end

  def start_updater_thread
    # 自動更新スレッド
    @updater_thread = Thread.start do
      every_nseconds UPDATE_INTERVAL_MINUTE * 60 do
        update_channel_list
      end
    end
  end

  def start_peercast_watcher_thread
    host, port = ::Settings[:USER_PEERCAST].split(/:/)
    @peercast_watcher_thread =
      Thread.start(host, port.to_i, &method(:peercast_watcher))
  end

  def peercast_watcher(host, port)
    watcher = PeercastHealth.new(host, port, 0.5)
    every_nseconds 5 * 60 do
      unless watcher.check
        self.notification =
          "#{host}:#{port} に接続できません。(#{watcher.error_reason})"
      end
    end
  end

  def notify_observers(*args)
    STDERR.puts "mw_model: notify_observers: #{args.inspect}"
    super
  end
end
