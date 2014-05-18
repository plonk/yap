# -*- coding: utf-8 -*-
# チャンネルリストのコンテキストメニュー
class ChannelListView::ContextMenu < Gtk::Menu
  include Gtk

  def initialize(mw_model)
    @mw_model = mw_model

    super()

    @play = MenuItem.new('再生')
    @play.signal_connect('activate') do
      @mw_model.play(@channel) if @channel
    end
    append(@play)

    append(MenuItem.new) # separator

    @contact_url = MenuItem.new('コンタクトURLを開く')
    @contact_url.signal_connect('activate') do
      Environment.open(@channel.contact_url) if @channel
    end
    append(@contact_url)

    @chat_url = MenuItem.new('チャットURLを開く')
    @chat_url.signal_connect('activate') do
      Environment.open(@channel.chat_url) if @channel
    end
    append(@chat_url)

    @stat_url = MenuItem.new('統計URLを開く')
    @stat_url.signal_connect('activate') do
      Environment.open(@channel.stat_url) if @channel
    end
    append(@stat_url)

    append(MenuItem.new)

    @fav = MenuItem.new('お気に入りに追加/削除')
    @fav.signal_connect('activate') do
      @mw_model.toggle_favorite
    end
    append(@fav)

    append(MenuItem.new)

    ham = MenuItem.new('Ham')
    ham.signal_connect('activate') do
      @mw_model.train_channel(@channel, :ham)
    end
    append(ham)

    spam = MenuItem.new('Spam')
    spam.signal_connect('activate') do
      @mw_model.train_channel(@channel, :spam)
    end
    append(spam)

    append(MenuItem.new)

    @info = MenuItem.new('チャンネル情報')
    @info.signal_connect('activate') do
      fail unless @channel

      @mw_model.show_channel_info(@channel)
    end
    append(@info)
  end

  def associate(channel)
    @contact_url.sensitive = channel.contact_url != ''
    @chat_url   .sensitive = channel.chat_url != ''
    @stat_url   .sensitive = channel.stat_url != ''
    @play       .sensitive = channel.playable?

    @channel = channel
  end
end
