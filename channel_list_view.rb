# -*- coding: utf-8 -*-
require_relative 'gtk_helper'
require_relative 'cell_renderer_set'
require_relative 'channel_list_store'

class ChannelListView < Gtk::TreeView; end

require_relative 'clv_context_menu'

# チャンネルリストのビュー
class ChannelListView < Gtk::TreeView
  include Pango, Gtk, GtkHelper
  include Observable

  attr_accessor :scrolled_window
  attr_accessor :list_store

  GRID_LINE_CONSTANTS =
    [GRID_LINES_NONE,
     GRID_LINES_HORIZONTAL,
     GRID_LINES_VERTICAL,
     GRID_LINES_BOTH]

  # ソートするカラムを column_id に切り替える手続きオブジェクトを返す。
  def sort_changer(column_id, order)
    fail ArgumentError, 'unknown sort order' unless
      [SORT_ASCENDING, SORT_DESCENDING].include? order
    lambda do |_tree_view_column|
      @list_store.set_sort_column_id column_id, order
    end
  end

  def update(message, *args)
    if self.respond_to? message
      Gtk.queue do
        __send__(message, *args)
      end
    end
  end

  def favorites_changed
    refresh
  end

  def channel_list_updated
    refresh
  end

  def settings_changed
    @cr.set_cell_renderer_font
    set_view_preferences
  end

  def create_columns
    @yp_column       = TreeViewColumn.new('YP', @cr.yp)
    @name_column     = TreeViewColumn.new('名前', @cr.name, text: 0)
      .set(resizable: true, min_width: 100, expand: true)
    @genre_column    = TreeViewColumn.new('ジャンル', @cr.genre, text: 1)
      .set(resizable: true, min_width: 50, expand: true)
    @detail_column   = TreeViewColumn.new('配信内容', @cr.detail, text: 2)
      .set(resizable: true, min_width: 240, expand: true)
    @listener_column = TreeViewColumn.new('人数', @cr.listener, text: 3)
    @time_column     = TreeViewColumn.new('時間', @cr.time, text: 4)
    @bitrate_column  = TreeViewColumn.new('Bps', @cr.bitrate, text: 5)
  end

  def connect_sort_changers
    [[@yp_column,       ChannelListStore::FLD_YPNAME,   SORT_ASCENDING],
     [@name_column,     ChannelListStore::FLD_CHNAME,   SORT_ASCENDING],
     [@genre_column,    ChannelListStore::FLD_GENRE,    SORT_ASCENDING],
     [@detail_column,   ChannelListStore::FLD_DETAIL,   SORT_ASCENDING],
     [@listener_column, ChannelListStore::FLD_LISTENER, SORT_DESCENDING],
     [@time_column,     ChannelListStore::FLD_TIME,     SORT_DESCENDING],
     [@bitrate_column,  ChannelListStore::FLD_BITRATE,  SORT_DESCENDING]]
      .each do |col, fldnum, order|
      col.signal_connect('clicked', &sort_changer(fldnum, order))
    end
  end

  def set_cell_data_funcs
    [[@yp_column,       @cr.yp,       :yp_cell_data_func],
     [@name_column,     @cr.name,     :name_cell_data_func],
     [@genre_column,    @cr.genre,    :genre_cell_data_func],
     [@detail_column,   @cr.detail,   :detail_cell_data_func],
     [@listener_column, @cr.listener, :listener_cell_data_func],
     [@time_column,     @cr.time,     :time_cell_data_func],
     [@bitrate_column,  @cr.bitrate,  :bitrate_cell_data_func]]
      .each do |col, cr, sym|
      col.set_cell_data_func(cr, &@cr.method(sym))
    end
  end

  def append_columns
    [@yp_column, @name_column, @genre_column, @detail_column,
     @listener_column, @time_column, @bitrate_column].each do |col|
      append_column col
    end
  end

  def install_columns
    create_columns
    connect_sort_changers
    set_cell_data_funcs
    append_columns
    set(headers_clickable: true)
  end

  def initialize(mw_model, filter_fn)
    @mw_model = mw_model
    @mw_model.add_observer(self, :update)

    @suppress_selection_change = false

    @list_store = ChannelListStore.new(filter_fn)
    @cr = CellRendererSet.new(@mw_model)

    super(@list_store)

    do_layout
    refresh
  end

  def install_context_menu
    @context_menu = ContextMenu.new(@mw_model).show_all

    self.events = Gdk::Event::BUTTON_PRESS_MASK
    signal_connect('button_press_event', &method(:on_button_press_event))
  end

  def setup_selection
    selection.mode = SELECTION_BROWSE
    # 行が選択された時に実行される
    selection.signal_connect('changed') do
      @mw_model.select_channel(selected_channel) unless
        @suppress_selection_change
    end
  end

  def do_layout
    setup_selection
    install_columns
    set_view_preferences
    install_context_menu
    setup_own_callbacks
  end

  def setup_own_callbacks
    signal_connect('row-activated') do |_treeview, path, _column|
      ch = @list_store.path_to_channel(path)
      fail unless ch
      @mw_model.play(ch) if ch.playable?
    end
  end

  def silently
    @suppress_selection_change = true
    yield
    @suppress_selection_change = false
  end

  def set_view_preferences
    set(rules_hint: ::Settings[:RULES_HINT],
        enable_grid_lines: GRID_LINE_CONSTANTS[::Settings[:GRID_LINES]])
  end

  def handle_right_click(event)
    if selected_channel
      @context_menu.associate(selected_channel)
      @context_menu.popup(nil, nil, event.button, event.time)
    end
    true
  end

  def handle_middle_click(_event)
    # 中クリックの位置によらず、既に選択されている行のコンタクト
    # URLが開かれるのは問題。
    Environment.open(selected_channel.contact_url) if selected_channel
    true
  end

  def on_button_press_event(_w, event)
    # なんで Button press 以外のイベントが来るんだろう？
    STDERR.puts event.inspect unless
      event.event_type == Gdk::Event::BUTTON_PRESS

    if event.button == 3
      handle_right_click(event)
    elsif event.button == 2
      handle_middle_click(event)
    else
      false
    end
  end

  def search(term)
    @cr.highlight_term = term
    if term == ''
      self.model = @list_store
    else
      self.model = @list_store.create_filter(term)
    end
  end

  def selected_channel
    iter = selection.selected

    if iter
      @list_store.iter_to_channel(iter)
    else
      nil
    end
  end

  def unselect_current_selection
    iter = selection.selected
    selection.unselect_path iter.path if iter
  end

  def select_appropriate_row
    to_be_selected = @list_store.channel_to_path @mw_model.selected_channel
    if to_be_selected
      silently { selection.select_path to_be_selected }
    else
      silently { unselect_current_selection }
    end
  end

  def schedule_vadjustment_restore(value)
    Thread.start do
      sleep 0.5
      Gtk.queue do
        @scrolled_window.vadjustment.value =
          [@scrolled_window.vadjustment.upper, value].min
      end
    end
  end

  def refresh
    value = @scrolled_window.vadjustment.value if @scrolled_window

    silently { @list_store.replace(@mw_model.master_table) }

    select_appropriate_row

    schedule_vadjustment_restore(value) if @scrolled_window

    changed
    notify_observers
  end

  def selected_channel_changed
    select_appropriate_row
  end
end
