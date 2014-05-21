# -*- coding: utf-8 -*-
# チャンネルリストのコンテキストメニュー
class ChannelListView::ContextMenu < Gtk::Menu
  include Gtk

  def initialize(mw_model, ui)
    @mw_model = mw_model
    @ui = ui

    super()

    do_layout
  end

  def do_layout
    create_menu_items
    append_menu_items
    connect_callbacks
  end

  def separator
    MenuItem.new
  end

  def append_menu_items
    [@play, separator, @contact_url, @chat_url, @stat_url, separator,
     @fav, separator, @ham, @spam, separator, @info].each(&method(:append))
  end

  def create_menu_items
    @play        = MenuItem.new '再生'
    @contact_url = MenuItem.new 'コンタクトURLを開く'
    @chat_url    = MenuItem.new 'チャットURLを開く'
    @stat_url    = MenuItem.new '統計URLを開く'
    @fav         = MenuItem.new 'お気に入りに追加/削除'
    @ham         = MenuItem.new 'Ham'
    @spam        = MenuItem.new 'Spam'
    @info        = MenuItem.new 'チャンネル情報'
  end

  def on_activate(item, &block)
    item.signal_connect('activate', &block)
  end

  def connect_callbacks
    on_activate(@play) { @mw_model.play(@channel) }
    on_activate(@contact_url) { Environment.open(@channel.contact_url) }
    on_activate(@chat_url) { Environment.open(@channel.chat_url) }
    on_activate(@stat_url) { Environment.open(@channel.stat_url) }
    on_activate(@fav) { @mw_model.toggle_favorite }
    on_activate(@ham) { @mw_model.train_channel(@channel, :ham) }
    on_activate(@spam) { @mw_model.train_channel(@channel, :spam) }
    on_activate(@info) { @ui.show_channel_info(@channel) }
  end

  def popup(*args)
    return unless @channel

    super(*args)
  end

  def associate(channel)
    return unless channel

    @contact_url.sensitive = channel.contact_url != ''
    @chat_url   .sensitive = channel.chat_url != ''
    @stat_url   .sensitive = channel.stat_url != ''
    @play       .sensitive = channel.playable?

    @channel = channel
  end
end
