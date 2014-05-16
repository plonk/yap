# -*- coding: utf-8 -*-
require 'gtk2'
require_relative 'mw_model'
require_relative 'channel_info_label'
require_relative 'channel_name_label'
require_relative 'process_manager'
require_relative 'yellow_page_manager'
require_relative 'information_area'
require_relative 'channel_list_page'
require_relative 'utility'
require_relative 'notification'
require_relative 'gtk_helper'
require_relative 'about_dialog'
require_relative 'column_settings_dialog'

# メインウィンドウクラス。MainWindowModel とは深い仲。
class MainWindow < Gtk::Window
  include Gtk
  include GtkHelper

  def initialize(model)
    super(Window::TOPLEVEL)

    @model = model

    initialize_components
    create_status_icon

    setup_accel_keys
    signal_connect('destroy', &method(:main_window_destroy_callback))

    @model.add_observer(self, :update)
    @model.start_helper_threads
  end

  def initialize_components
    widget_layout
    connect_callbacks
  end

  def create_default_action_group
    action_group = ActionGroup.new('default action group')
    action_group.add_actions \
    [
      ['FileMenuAction', Stock::FILE, 'ファイル(_F)', '', nil, proc {}],
      ['ReloadAction', Stock::REFRESH, '更新(_R)', '', nil, proc { @model.reload }],
      ['ExitAction', Stock::QUIT, '終了(_X)', '', nil, proc { quit }],

      ['ViewMenuAction', nil, '表示(_V)', '', nil, proc {}],

      ['FavoritesMenuAction', nil, 'お気に入り(_A)', '', nil, proc {}],
      ['OrganizeFavoritesAction', nil, '整理(_A)', '', nil, proc { run_favorite_dialog }],

      ['ToolMenuAction', nil, 'ツール(_T)', '', nil, proc {}],
      ['SettingsAction', Stock::PREFERENCES, '一般設定(_S)', '', nil, proc { open_settings_dialog }],
      ['TypeAssocAction', nil, 'プレーヤー設定(_T)', '', nil, proc {}],
      ['YellowPageAction', nil, 'YP 設定(_Y)', '', nil, proc { open_yellow_page_manager }],
      ['ColumnSettingsAction', nil, 'カラム設定(_C)', '', nil, proc { open_column_settings_dialog }],
      ['ProcessManagerAction', nil, 'プロセスマネージャ(_P)', '', nil, proc { open_process_manager }],

      ['HelpMenuAction', Stock::HELP, 'ヘルプ(_H)', '', nil, proc {}],
      ['AboutAction', Stock::ABOUT, 'このアプリケーションについて(_A)', '', nil, proc { run_about_dialog }]
    ]

    # [name, stock_id, label, accelarator, tooltip, proc, is_active]
    action_group.add_toggle_actions \
    [
      ['ToolbarVisibleAction', nil, 'ツールバー(_T)', '', nil, proc { toggle_toolbar_visibility }, ::Settings[:TOOLBAR_VISIBLE]],
      ['ChannelInfoVisibleAction', nil, 'チャンネル情報(_C)', '', nil, proc { toggle_channel_info_visibility }, ::Settings[:CHANNEL_INFO_VISIBLE]]
    ]
    action_group
  end

  def widget_layout
    set_default_size(640, 640)
    set(icon: Resource['yap.png'], border_width: 0)

    @ui_manager = UIManager.new
    @ui_manager.add_ui(Resource['ui_definition.xml'])

    @action_group = create_default_action_group
    @ui_manager.insert_action_group(@action_group, 0)

    create(VBox, false, 0) do |outermost_vbox|
      outermost_vbox.pack_start @ui_manager['/ui/menubar'], false

      @toolbar = create(Toolbar,
                        toolbar_style: Toolbar::Style::BOTH_HORIZ) do |toolbar|
        @reload_toolbutton =
          create(ToolButton, Stock::REFRESH,
                 label: 'すぐに更新',
                 tooltip_text:
                 '次の自動更新を待たずにチャンネルリストを更新します' \
                 "\n（#{MainWindowModel::MANUAL_UPDATE_INTERVAL}秒間に" \
                 "#{MainWindowModel::MANUAL_UPDATE_COUNT}回まで実行できます）",
                 important: true)

        if $ENABLE_VIEWLOG
          @viewlog_toolbutton = create(ToolButton, Stock::JUSTIFY_LEFT,
                                       label: 'ログ',
                                       important: true)
        end
        @settings_toolbutton = create(ToolButton,
                                      Stock::PREFERENCES,
                                      important: true)

        @spring = create(SeparatorToolItem, expand: true, draw: false)

        toolbar.add @reload_toolbutton
        toolbar.add @viewlog_toolbutton if $ENABLE_VIEWLOG
        toolbar.add @settings_toolbutton

        outermost_vbox.pack_start(toolbar, false)
      end

      @information_area = InformationArea.new(@model)
      outermost_vbox.pack_start(@information_area, false)

      @notebook = create(Notebook) do |notebook|
        @channel_list_page = ChannelListPage.new(@model, 'すべて')
        notebook.append_page(@channel_list_page, @channel_list_page.label)
        fav_page = ChannelListPage.new(@model, 'お気に入り',
                                       proc do |ch|
                                         @model.favorites.include? ch.name
                                       end)
        notebook.append_page(fav_page, fav_page.label)

        outermost_vbox.pack_start(notebook, true)
      end

      @notification = Notification.new
      outermost_vbox.pack_start(@notification, false)

      add outermost_vbox
    end
  end

  def connect_callbacks
    @reload_toolbutton
      .signal_connect('clicked', &method(:reload_toolbutton_callback))

    if $ENABLE_VIEWLOG
      @viewlog_toolbutton.signal_connect('clicked') do
        d = LogDialog.new(self)
        d.show_all
      end
    end

    @settings_toolbutton.signal_connect('clicked') do
      open_settings_dialog
    end
  end

  def create_status_icon
    @status_icon = create(StatusIcon,
                          pixbuf: Gdk::Pixbuf.new(Resource['yap.png']),
                          tooltip: 'YAP')

    # クリックされたらメインウィンドウの表示・非表示を切り替える。
    @status_icon.signal_connect('activate') do
      if visible?
        hide
      else
        show
        deiconify
      end
    end

    menu = create_status_icon_menu
    @status_icon.signal_connect('popup-menu') do |_tray, button, time|
      menu.popup(nil, nil, button, time)
    end

    # メインウィンドウが最小化されたら非表示にする。
    signal_connect('window-state-event') do |_win, e|
      if e.changed_mask.iconified?
        if e.new_window_state.iconified? && !e.new_window_state.withdrawn?
          hide
          next true
        end
      end
      false
    end
  end

  def settings_changed
    @toolbar.visible = ::Settings[:TOOLBAR_VISIBLE]
    @information_area.visible = ::Settings[:CHANNEL_INFO_VISIBLE]
  end

  def toggle_toolbar_visibility
    ::Settings[:TOOLBAR_VISIBLE] = !::Settings[:TOOLBAR_VISIBLE]
  end

  def toggle_channel_info_visibility
    ::Settings[:CHANNEL_INFO_VISIBLE] = !::Settings[:CHANNEL_INFO_VISIBLE]
  end

  def create_status_icon_menu
    create(Menu) do |menu|
      menu.append create(ImageMenuItem, Stock::INFO,
                         on_activate: proc { run_about_dialog })
      menu.append SeparatorMenuItem.new
      menu.append create(ImageMenuItem, Stock::QUIT,
                         on_activate: proc { quit })
    end.show_all
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

  def update(message, *args)
    if self.respond_to? message
      # 別スレッドから呼ばれる可能性があるはず。
      Gtk.queue do
        __send__(message, *args)
      end
    end
  end

  def favorites_changed
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
    d = SettingsDialog.new(self)
    d.show_all
  end

  def open_yellow_page_manager
    YellowPageManager.new(self).show_all
  end

  def open_column_settings_dialog
    ColumnSettingsDialog.new(self).show_all
  end

  def setup_accel_keys
    accel_group = Gtk::AccelGroup.new
    accel_group.connect(Gdk::Keyval::GDK_A,
                        Gdk::Window::CONTROL_MASK,
                        Gtk::ACCEL_VISIBLE) do
      open_process_manager
    end

    add_accel_group(accel_group)
  end

  def open_process_manager
    ProcessManager.new(self, @model).show_all
  end

  def finalize
    @model.finalize
    @model.delete_observer(self)
  end

  def main_window_destroy_callback(_widget)
    puts 'destroying main window'
    quit
  end

  def quit
    finalize
    Gtk.main_quit
  end

  def until_reload_toolbutton_available(sec)
    @reload_toolbutton.sensitive = (sec == 0)
    @reload_toolbutton.label = (sec == 0) ? 'すぐに更新' : "すぐに更新（あと#{sec}秒）"
  end

  # -- class MainWindow --

  def channel_list_updated
    update_window_title
  end

  # -- class MainWindow

  def reload_toolbutton_callback(_widget)
    STDERR.puts 'RELOAD CLICKED'
    @model.reload
  end

  def update_window_title
    # ウィンドウタイトルを更新する
    str = "YAP - #{Time.now.strftime('%H時%M分')}現在 " +
      "#{@model.total_channel_count} chが配信中"
    self.title = str
  end

  def notification_changed
    @notification.put_up(@model.notification)
  end
end
