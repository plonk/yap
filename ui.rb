# -*- coding: utf-8 -*-
require_relative 'info_dialog'
require_relative 'log_dialog'
require_relative 'favorite_dialog'
require_relative 'settings_dialog'
require_relative 'settings'
require_relative 'bandwidth_checker_manager'
require_relative 'main_window'

class UI
  include Gtk

  def initialize(model)
    @model = model

    @main_window = MainWindow.new(@model, self).show_all
    BandwidthCheckerManager.new @model
  end

  def run
    puts 'Going into the main loop'
    Gtk.main
  rescue Interrupt
    # なんか変だ
    window.finalize
  ensure
    if $RUNNING_ON_RUBYW
      File.open('outlog.txt', 'w') do |f|
        f.write $log.string
      end
    end
  end

  def open_log_dialog
    LogDialog.new(@main_window).show_all
  end

  def run_about_dialog
    YapAboutDialog.new.show_all
  end

  def show_channel_info(ch)
    dialog = InfoDialog.new(@main_window, ch).show_all
    dialog.signal_connect('response') do
      dialog.destroy
    end
  end

  def run_favorite_dialog
    dialog = FavoriteDialog.new(@main_window, @model.favorites.to_a).show_all
    dialog.run do |response|
      @model.favorites.replace(dialog.list) if response == Dialog::RESPONSE_OK
    end
    dialog.destroy
  end

  def open_settings_dialog
    SettingsDialog.new(@main_window).show_all
  end

  def open_yellow_page_manager
    YellowPageManager.new(@main_window).show_all
  end

  def open_column_settings_dialog
    ColumnSettingsDialog.new(@main_window).show_all
  end

  def open_process_manager
    ProcessManager.new(@main_window, @model).show_all
  end
end
