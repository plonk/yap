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

  def initialize(model, ui)
    super(Window::TOPLEVEL)

    @model = model
    @ui = ui

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

    setup_ui

    add create_outermost_vbox
  end

  def setup_ui
    @ui_manager = MainWindow::UIManager.new
    @action_group = MainWindow::ActionGroup.new(@model, @ui)
    @ui_manager.insert_action_group(@action_group, 0)
  end

  def create_outermost_vbox
    create(VBox, false, 0) do |outermost_vbox|
      @toolbar = MainWindow::Toolbar.new(@model, @ui)
      @information_area = InformationArea.new(@model)
      @notebook = MainWindow::Notebook.new(@model, @ui)
      @notification = Notification.new(@model)

      [@ui_manager['/ui/menubar'], @toolbar, @information_area, @notebook,
       @notification].each do |widget|
        outermost_vbox.pack_start(widget, widget == @notebook)
      end
    end
  end

  def toggle_toolbar_visibility
    ::Settings[:TOOLBAR_VISIBLE] = !::Settings[:TOOLBAR_VISIBLE]
  end

  def toggle_channel_info_visibility
    ::Settings[:CHANNEL_INFO_VISIBLE] = !::Settings[:CHANNEL_INFO_VISIBLE]
  end

  def show_all
    super
    @toolbar.visible = ::Settings[:TOOLBAR_VISIBLE]
    @information_area.visible = ::Settings[:CHANNEL_INFO_VISIBLE]
    self
  end

  def on_destroy(_widget)
    puts 'destroying main window'
    @ui.quit
  end

  def channel_list_updated
    update_window_title
  end

  def update_window_title
    time = Time.now.strftime('%H時%M分')
    channels = @model.total_channel_count
    self.title = "YAP - #{time}現在 #{channels} chが配信中"
  end
end
