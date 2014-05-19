# -*- coding: utf-8 -*-
require_relative 'channel_list_view'
require_relative 'tab_label'
require_relative 'search_field'

class Page < Gtk::VBox
  include Observable
  attr_reader :title, :label

  def initialize
    super()

    @label = TabLabel.new(self)
  end

  def title= str
    @title = str
    changed
    notify_observers
  end
end

# Notebook のページ。チャンネルリスト、検索フィールドを含む。
# タブラベルにチャンネル数を通知する。
class ChannelListPage < Page
  include Gtk
  include GtkHelper

  def initialize(model, ui, title, func = proc { true })
    super()

    @model = model
    @ui = ui
    @func = func
    set(homogeneous: false, spacing: 2)
    self.title = @base_title = title

    do_layout

    @channel_list_view.add_observer(self)

    signal_connect('destroy') do
      @channel_list_view.delete_observer(self)
    end
  end

  def update
    self.title = "#{@base_title}(#{@channel_list_view.list_store.count})"
  end

  def do_layout
    @channel_list_view = ChannelListView.new(@model, @ui, @func)

    @search_field = SearchField.new(@channel_list_view)
    pack_start(@search_field, false)

    @channel_list_view.list_store.signal_connect('row-inserted') do
      changed
      notify_observers
    end
    @channel_list_view.list_store.signal_connect('row-deleted') do
      changed
      notify_observers
    end
    create(ScrolledWindow,
           shadow_type: SHADOW_ETCHED_IN,
           hscrollbar_policy: POLICY_AUTOMATIC,
           vscrollbar_policy: POLICY_ALWAYS) do |sw|
      sw.add @channel_list_view
      @channel_list_view.scrolled_window = sw
      pack_start(sw, true)
    end
  end
end

class FavoriteListPage < ChannelListPage
  def initialize(model, ui)
    filter_func = proc { |ch| model.favorites.include? ch.name }
    super(model, ui, 'お気に入り', filter_func)
  end
end

class YellowPagePage < Page
  include Gtk
  include DispatchingObserver

  def initialize(model, ui)
    @model = model
    @ui = ui

    super()

    @model.add_observer(self)
    self.title = 'YPPage'
    pack_start(@widget = widget, true)
    update_widget_text
  end

  def update_widget_text
    @widget.text = @model.yellow_pages.map do |yp|
      "#{yp.name} - #{yp.loaded? ? 'loaded' : 'empty'}, #{yp.count} channels"
    end.join("\n")
  end

  def widget
    Label.new()
  end

  def settings_changed
    update_widget_text
  end
end
