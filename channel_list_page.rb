# -*- coding: utf-8 -*-
require_relative 'channel_list_view'
require_relative 'tab_label'
require_relative 'search_field'
require_relative 'notebook_page'

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
  include GtkHelper
  include DispatchingObserver

  def initialize(model, ui)
    @model = model
    @ui = ui

    super()

    @model.add_observer(self)
    self.title = 'イエローページ'

    do_layout
  end

  def do_layout
    align = Alignment.new(0.5, 0.5, 0, 0)
    align.add create_table
    pack_start(align, true)
  end

  def create_table
    create(Table, 2, @model.yellow_pages.size,
           row_spacings: 5,
           column_spacings: 10) do |table|
      @model.yellow_pages.each_with_index do |yp, index|
        label = Label.new("#{yp.name} - #{yp.loaded? ? 'loaded' : 'empty'}, #{yp.count} channels")
        table.attach_defaults(label, 0, 1, index, index + 1)

        button = Button.new('load')
        table.attach_defaults(button, 1, 2, index, index + 1)
      end
    end
  end

  def settings_changed
  end
end
