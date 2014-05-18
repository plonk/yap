# -*- coding: utf-8 -*-
require 'gtk2'
require_relative 'mw_model'
require_relative 'process_manager'
require_relative 'yellow_page_manager'
require_relative 'channel_list_page'
require_relative 'utility'
require_relative 'gtk_helper'
require_relative 'about_dialog'
require_relative 'column_settings_dialog'
require_relative 'notification'
require_relative 'information_area'
require_relative 'action_group'
require_relative 'ui_manager'
require_relative 'toolbar'
require_relative 'status_icon'
require_relative 'notebook'

# メインウィンドウクラス。MainWindowModel とは深い仲。
class MainWindow < Gtk::Window
  include Gtk
  include GtkHelper
  include DispatchingObserver

  def initialize(model)
    super(Window::TOPLEVEL)

    @model = model

    widget_layout

    signal_connect('destroy', &method(:on_destroy))

    observer_setup(@model)
    @model.start_helper_threads
  end

  def set_own_properties
    set_default_size(640, 640)
    set(icon: Resource['yap.png'], border_width: 0)
  end

  def widget_layout
    set_own_properties

    MainWindow::StatusIcon.new(self)

    setup_ui

    add create_outermost_vbox
  end

  def setup_ui
    @ui_manager = MainWindow::UIManager.new
    @action_group = MainWindow::ActionGroup.new(@model, self)
    @ui_manager.insert_action_group(@action_group, 0)
  end

  def create_outermost_vbox
    create(VBox, false, 0) do |outermost_vbox|
      menubar = @ui_manager['/ui/menubar']
      @toolbar = MainWindow::Toolbar.new(@model, self)
      @information_area = InformationArea.new(@model)
      @notebook = MainWindow::Notebook.new(@model)
      @notification = Notification.new

      [menubar, @toolbar, @information_area, @notebook, @notification]
        .zip([false, false, false, true, false]).each do |widget, expand|
        outermost_vbox.pack_start(widget, expand)
      end
    end
  end

  def open_log_dialog
    LogDialog.new(self).show_all
  end

  def toggle_toolbar_visibility
    ::Settings[:TOOLBAR_VISIBLE] = !::Settings[:TOOLBAR_VISIBLE]
  end

  def toggle_channel_info_visibility
    ::Settings[:CHANNEL_INFO_VISIBLE] = !::Settings[:CHANNEL_INFO_VISIBLE]
  end

  def run_about_dialog
    YapAboutDialog.new.show_all
  end

  def show_all
    super
    @toolbar.visible = ::Settings[:TOOLBAR_VISIBLE]
    @information_area.visible = ::Settings[:CHANNEL_INFO_VISIBLE]
  end

  def show_channel_info(ch)
    dialog = InfoDialog.new(self, ch)
    dialog.show_all
    dialog.signal_connect('response') do
      dialog.destroy
    end
  end

  def run_favorite_dialog
    dialog = FavoriteDialog.new(self, @model.favorites.to_a)
    dialog.show_all
    dialog.run do |response|
      @model.favorites.replace(dialog.list) if response == Dialog::RESPONSE_OK
    end
    dialog.destroy
  end

  def open_settings_dialog
    SettingsDialog.new(self).show_all
  end

  def open_yellow_page_manager
    YellowPageManager.new(self).show_all
  end

  def open_column_settings_dialog
    ColumnSettingsDialog.new(self).show_all
  end

  def open_process_manager
    ProcessManager.new(self, @model).show_all
  end

  def finalize
    @model.finalize
  end

  def on_destroy(_widget)
    puts 'destroying main window'
    quit
  end

  def quit
    finalize
    Gtk.main_quit
  end

  def channel_list_updated
    update_window_title
  end

  def update_window_title
    time = Time.now.strftime('%H時%M分')
    channels = @model.total_channel_count
    self.title = "YAP - #{time}現在 #{channels} chが配信中"
  end

  def notification_changed
    @notification.put_up(@model.notification)
  end
end
