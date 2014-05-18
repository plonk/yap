# -*- coding: utf-8 -*-
require_relative 'channel_list_view'
require_relative 'tab_label'
require_relative 'search_field'

# Notebook のページ。チャンネルリスト、検索フィールドを含む。
# タブラベルにチャンネル数を通知する。
class ChannelListPage < Gtk::VBox
  include Gtk
  include GtkHelper
  include Observable

  attr_reader :title, :label

  def initialize(model, title, func = proc { true })
    super()

    @model = model
    @func = func
    set(homogeneous: false, spacing: 2)
    @base_title = title

    do_layout

    @channel_list_view.add_observer(self)

    @label = TabLabel.new(self)

    signal_connect('destroy') do
      @channel_list_view.delete_observer(self)
    end
  end

  def title
    "#{@base_title}(#{@channel_list_view.list_store.count})"
  end

  def update
    changed
    notify_observers
  end

  def do_layout
    @channel_list_view = ChannelListView.new(@model, @func)

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
