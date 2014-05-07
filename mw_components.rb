# -*- coding: utf-8 -*-
require_relative 'main_window'
require_relative 'channel_list_view'
require_relative 'utility'
require_relative 'notification'

class MainWindow
  include GtkHelper

  def initialize_components
    widget_layout
    connect_callbacks
  end

  def widget_layout
    @outermost_vbox = VBox.new(false, 0)
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

    @channeldb_toolbutton = create(ToolButton, Stock::YES, 
                                   label: "チャンネルDB",
                                   important: true)

    @spring = create(SeparatorToolItem, expand: true, draw: false)

    @restart_toolbutton = create(ToolButton, Stock::QUIT, label: "再起動", important: true)

    @about_toolbutton = create(ToolButton, Stock::ABOUT, important: true)

    @toolbar.add @reload_toolbutton
    @toolbar.add @favorite_toolbutton
    @toolbar.add @viewlog_toolbutton if $ENABLE_VIEWLOG
    @toolbar.add @settings_toolbutton
    @toolbar.add @channeldb_toolbutton
    @toolbar.add @spring
    @toolbar.add @restart_toolbutton
    @toolbar.add @about_toolbutton

    @outermost_vbox.pack_start(@toolbar, false)

    @mainarea_vbox = create(VBox, homogeneous: false, spacing: 5, border_width: 10)

    expander = Expander.new('チャンネル情報')
    expander.add @mainarea_vbox
    @outermost_vbox.pack_start(expander, false)

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

    set_default_size( 640, 640)
    border_width = 0 # 10
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
      d = SettingsDialog.new(self)
      d.show_all
    end

    @channeldb_toolbutton.signal_connect("clicked") do 
      d = ChannelDBDialog.new(self)
      d.show_all
    end

    @restart_toolbutton.signal_connect("clicked") do
      $RESTART_FLAG = true
      destroy
    end

    @clear_button.signal_connect("clicked") do
      @model.search_term = ""
    end


    @favorite_toggle_button.signal_connect("toggled", &method(:favorite_toggle_button_toggled_callback))

    @about_toolbutton.signal_connect('clicked') do 
      comments = <<EOS
GTK+ #{Gtk::VERSION.join('.')}
Ruby/GTK: #{Gtk::BINDING_VERSION.join('.')} (built for #{Gtk::BUILD_VERSION.join('.')})
Ruby: #{RUBY_VERSION} [#{RUBY_PLATFORM}]
EOS
      comments = comments.chomp
      dialog = create(AboutDialog,
                      modal: true,
                      program_name: "YAP",
                      version: "0.0.3",
                      comments: comments,
                      authors: ['予定地'],
                      website: 'https://github.com/plonk/yap')
      dialog.run do |response|
        dialog.destroy
      end
    end
  end
end
