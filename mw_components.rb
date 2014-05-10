# -*- coding: utf-8 -*-
require_relative 'main_window'
require_relative 'channel_list_page'
require_relative 'utility'
require_relative 'notification'
require_relative 'gtk_helper'

class MainWindow
  include GtkHelper

  def initialize_components
    widget_layout
    connect_callbacks
  end

  def create_default_action_group
    action_group = ActionGroup.new('default action group')
    action_group.add_actions \
    [
     ["FileMenuAction", Stock::FILE, "ファイル(_F)", "", nil, proc { }],
     ["ReloadAction", Stock::REFRESH, "更新(_R)", "", nil, proc { @model.reload }],
     ["ExitAction", Stock::QUIT, "終了(_X)", "", nil, proc { quit }],

     ["ViewMenuAction", nil, "表示(_V)", "", nil, proc { }],

     ["FavoritesMenuAction", nil, "お気に入り(_A)", "", nil, proc { }],
     ["OrganizeFavoritesAction", nil, "整理(_A)", "", nil, proc { run_favorite_dialog }],

     ["ToolMenuAction", nil, "ツール(_T)", "", nil, proc { }],
     ["SettingsAction", Stock::PREFERENCES, "一般設定(_S)", "", nil, proc { open_settings_dialog }],
     ["TypeAssocAction", nil, "プレーヤー設定(_T)", "", nil, proc { }],
     ["YellowPageAction", nil, "YP 設定(_Y)", "", nil, proc { open_yellow_page_manager }],
     ["ProcessManagerAction", nil, "プロセスマネージャ(_P)", "", nil, proc { open_process_manager }],

     ["HelpMenuAction", Stock::HELP, "ヘルプ(_H)", "", nil, proc { }],
     ["AboutAction", Stock::ABOUT, "このアプリケーションについて(_A)", "", nil, proc { run_about_dialog }],
    ]

    # [name, stock_id, label, accelarator, tooltip, proc, is_active]
    action_group.add_toggle_actions \
    [
     ["ToolbarVisibleAction", nil, "ツールバー(_T)", "", nil, proc { toggle_toolbar_visibility }, ::Settings[:TOOLBAR_VISIBLE] ],
     ["ChannelInfoVisibleAction", nil, "チャンネル情報(_C)", "", nil, proc { toggle_channel_info_visibility }, ::Settings[:CHANNEL_INFO_VISIBLE] ],
    ]
    action_group
  end

  def widget_layout
    set_default_size(640, 640)
    set(icon: Resource['yap.png'], border_width: 0)

    @ui_manager = UIManager.new
    @ui_manager.add_ui(Resource["ui_definition.xml"])

    @action_group = create_default_action_group
    @ui_manager.insert_action_group(@action_group, 0)

    create(VBox, false, 0) do |outermost_vbox|
      outermost_vbox.pack_start @ui_manager['/ui/menubar'], false

      @toolbar = create(Toolbar, toolbar_style: Toolbar::Style::BOTH_HORIZ) do |toolbar|
        @reload_toolbutton = create(ToolButton, Stock::REFRESH,
                                    label: "すぐに更新",
                                    tooltip_text: ("次の自動更新を待たずにチャンネルリストを更新します" +
                                                   "\n（#{MainWindowModel::MANUAL_UPDATE_INTERVAL}秒間に#{MainWindowModel::MANUAL_UPDATE_COUNT}回まで実行できます）"),
                                    important: true)

        if $ENABLE_VIEWLOG
          @viewlog_toolbutton = create(ToolButton, Stock::JUSTIFY_LEFT,
                                       label: "ログ",
                                       important: true)
        end
        @settings_toolbutton = create(ToolButton, Stock::PREFERENCES, important: true)

        @spring = create(SeparatorToolItem, expand: true, draw: false)

        toolbar.add @reload_toolbutton
        toolbar.add @viewlog_toolbutton if $ENABLE_VIEWLOG
        toolbar.add @settings_toolbutton

        outermost_vbox.pack_start(toolbar, false)
      end

      @information_area = InformationArea.new(@model)
      outermost_vbox.pack_start(@information_area, false)

      @notebook = create(Notebook) do |notebook|
        @channel_list_page = ChannelListPage.new(@model)
        notebook.append_page(@channel_list_page, Label.new('すべて'))
        notebook.append_page(ChannelListPage.new(@model,
                                                 proc { |ch| @model.favorites.include? ch.name }),
                             Label.new('お気に入り'))

        outermost_vbox.pack_start(notebook, true)
      end

      @notification = Notification.new
      outermost_vbox.pack_start(@notification, false)

      add outermost_vbox
    end
  end

  def connect_callbacks
    @reload_toolbutton.signal_connect("clicked", &method(:reload_toolbutton_callback))

    if $ENABLE_VIEWLOG
      @viewlog_toolbutton.signal_connect("clicked") do
        d = LogDialog.new(self)
        d.show_all
      end
    end

    @settings_toolbutton.signal_connect("clicked") do
      open_settings_dialog
    end
  end
end
