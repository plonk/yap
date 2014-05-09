# -*- coding: utf-8 -*-
require_relative 'main_window'
require_relative 'channel_list_view'
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
    @outermost_vbox = VBox.new(false, 0)

    @ui_manager = UIManager.new
    @ui_manager.add_ui(Resource.path("ui_definition.xml"))

    @action_group = create_default_action_group
    @ui_manager.insert_action_group(@action_group, 0)

    @outermost_vbox.pack_start @ui_manager['/ui/menubar'], false

    @toolbar = create(Toolbar, toolbar_style: Toolbar::Style::BOTH_HORIZ)

    @reload_toolbutton = create(ToolButton, Stock::REFRESH,
                                label: "すぐに更新",
                                tooltip_text: $MANUAL_UPDATE_INTERVAL == 0 ?
                                "次の自動更新を待たずにチャンネルリストを更新します" :
                                "次の自動更新を待たずにチャンネルリストを更新します" +
                                "\n（#{$MANUAL_UPDATE_INTERVAL}秒間に#{$MANUAL_UPDATE_COUNT}回まで実行できます）",
                                important: true)

    @favorite_toolbutton = create(MenuToolButton, Stock::ABOUT, # only for the star
                                  label: "お気に入り",
                                  important: true,
                                  tooltip_text: "配信中のお気に入りch")
    if $ENABLE_VIEWLOG
      @viewlog_toolbutton = create(ToolButton, Stock::JUSTIFY_LEFT,
                                   label: "ログ",
                                   important: true)
    end
    @settings_toolbutton = create(ToolButton, Stock::PREFERENCES, important: true)

    @spring = create(SeparatorToolItem, expand: true, draw: false)

    @toolbar.add @reload_toolbutton
    @toolbar.add @favorite_toolbutton
    @toolbar.add @viewlog_toolbutton if $ENABLE_VIEWLOG
    @toolbar.add @settings_toolbutton

    @outermost_vbox.pack_start(@toolbar, false)

    @mainarea_vbox = create(VBox, homogeneous: false, spacing: 5, border_width: 10)

    @outermost_vbox.pack_start(@mainarea_vbox, false)

    @channel_list_view = ChannelListView.new(@model)

    @channel_list_view_scrolled_window = create(ScrolledWindow, 
                                       shadow_type: SHADOW_ETCHED_IN,
                                       hscrollbar_policy: POLICY_AUTOMATIC,
                                       vscrollbar_policy: POLICY_ALWAYS)
    @channel_list_view_scrolled_window.add @channel_list_view

    hbox = HBox.new false, 15 # (homogeneous: false, spacing: 15) なぜか動かない

    @play_button = create(Button, 
                          tooltip_text: "チャンネルを再生する",
                          sensitive: false,
                          height_request: 75,
                          width_request: 120)
    @play_button.add Image.new Resource.path("play.ico")
    @play_button.signal_connect("clicked") do 
      if ch = @channel_list_view.get_selected_channel # ちゃんとYPも見たほうが良い
        @model.play(ch)
      end
    end
    hbox.pack_start(@play_button, false, false)

    @chname_label = ChannelNameLabel.new

    @little_vbox = VBox.new
    @little_vbox.pack_start(@chname_label, false)

    @info_label = ChannelInfoLabel.new
    @little_vbox.pack_start(@info_label)
    hbox.pack_start @little_vbox

    @favorite_toggle_button = create(ToggleButton, "",
                                     tooltip_text: "お気に入り",
                                     sensitive: false,
                                     draw_indicator: false)
    @favorite_toggle_button.child.set_markup(" <span foreground=\"gray\" size=\"xx-large\">★</span> ")
    align = Alignment.new(1, 0, 0, 0) # place in the top-right corner
    align.add @favorite_toggle_button
    hbox.pack_start(align, false, false)

    @mainarea_vbox.pack_start(hbox, false)

    @link_hbox = HBox.new(false, 5)
    @link_button = create(LinkButton, "", "",
                          xalign: 0)
    @link_button.child.ellipsize = Pango::Layout::ELLIPSIZE_END
    @link_button.signal_connect("clicked") do
      system("start", @link_button.uri)
      true
    end

    @detail_vbox = VBox.new

    @genre_label = create(Label, '',
                          wrap: true,
                          xalign: 0,
                          ellipsize: Pango::Layout::ELLIPSIZE_END)
    genre_hbox = HBox.new(false, 5)
    genre_hbox.pack_start(Label.new("　　ジャンル："), false)
    genre_hbox.pack_start(@genre_label, true);
    @detail_vbox.pack_start(genre_hbox, false)

    bbs_label = Label.new("　　　掲示板：")
    @favicon_image = Image.new
    @link_hbox.pack_start(bbs_label, false)
    @link_hbox.pack_start(@favicon_image, false)
    @link_hbox.pack_start(@link_button, true)

    @mainarea_vbox.pack_start(@detail_vbox, false)

    @search_label = Label.new("")
    @link_hbox.pack_start(@search_label, false)
    @search_field = Entry.new
    @search_field.set_no_show_all(true) # なんだかわからないけど、フォーカスがおかしくなるので、メインウィンドウを show してから、show する
    @search_term = ""
    @link_hbox.pack_start(@search_field, false)
    @clear_button = create(Button, " ☓ ", tooltip_text: "入力欄をクリアして検索をやめる")
    @search_field.signal_connect("activate", &method(:search_field_activate_callback))
    @link_hbox.pack_start(@clear_button, false)

    @mainarea_vbox.pack_start(@link_hbox, false)

    @outermost_vbox.pack_start(@channel_list_view_scrolled_window, true)

    @notification = Notification.new
    @outermost_vbox.pack_start(@notification, false)

    set_default_size(640, 640)
    self.icon = Resource.path 'yap.png'
    self.border_width = 0 # 10
    add @outermost_vbox
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

    @clear_button.signal_connect("clicked") do
      @model.search_term = ""
    end


    @favorite_toggle_button.signal_connect("toggled", &method(:favorite_toggle_button_toggled_callback))
  end
end
