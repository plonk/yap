# -*- coding: utf-8 -*-
require_relative 'info_dialog'
require_relative 'log_dialog'
require_relative 'favorite_dialog'
require_relative 'settings_dialog'
require_relative 'settings'
require_relative 'bandwidth_checker_manager'
require_relative 'main_window'
require_relative 'resource'

class UI
  include Gtk

  QUESTION_16 = Gdk::Pixbuf.new Resource['question16.ico']
  QUESTION_64 = Gdk::Pixbuf.new Resource['question64.ico']
  LOADING_16 = Gdk::Pixbuf.new Resource['loading.ico']

  def initialize(model)
    @model = model

    @main_window = MainWindow.new(@model, self).show_all
    MainWindow::StatusIcon.new(@main_window, self)
    BandwidthCheckerManager.new @model, @main_window
  end

  def run
    puts 'Going into the main loop'
    Gtk.main
  rescue Interrupt
    # なんか変だ
    finalize
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

  def finalize
    @model.finalize
  end

  def quit
    finalize
    Gtk.main_quit
  end
end
