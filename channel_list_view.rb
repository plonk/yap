# -*- coding: utf-8 -*-
require_relative 'gtk_helper'

class ChannelListView < Gtk::TreeView
end

require_relative 'clv_context_menu'

class ChannelListView < Gtk::TreeView
  include Pango, Gtk, GtkHelper
  include Observable

  attr_reader :count
  attr_accessor :scrolled_window

  FLD_CHNAME   = 0
  FLD_GENRE    = 1
  FLD_DETAIL   = 2
  FLD_LISTENER = 3
  FLD_TIME     = 4
  FLD_BITRATE  = 5
  FLD_CH_ID    = 6
  FLD_YPNAME   = 7

  FIELD_TYPES = [String,	# chname
                 String,	# genre
                 String,	# detail
                 Integer,	# listener
                 Integer,	# time
                 Integer,	# bitrate
                 String,	# ch_id
                 String]	# ypname

  def open_url(url)
    Environment.open(url)
  end

  TARGET_NAME_CELL_WIDTH = 16.0

  def name_cell_font(chname)
    font = Pango::FontDescription.new(::Settings[:LIST_FONT])
    half_widths = measure_width(chname)

    if half_widths > TARGET_NAME_CELL_WIDTH
      factor = TARGET_NAME_CELL_WIDTH / half_widths
      font.size = [10 * factor, 8].max * 1000
    end
    font
  end

  # foreground, background, weight
  def name_cell_font_style(chname)
    if @mw_model.favorites.include? chname
      # pink if favorite
      [nil, '#FFBBBB', WEIGHT_BOLD]
    elsif chname =~ /\(要帯域チェック\)$/
      [nil, 'yellow', nil]
    else
      [nil, nil, nil]
    end
  end

  def name_cell_data_func(_col, renderer, _model, iter)
    chname = iter[FLD_CHNAME]

    renderer.font = name_cell_font(chname)
    fg, bg, weight = name_cell_font_style(chname)
    renderer.set(foreground: fg,
                 background: bg)
    renderer.set(weight: weight) if weight
    renderer.set_property('markup',
                          get_highlighted_markup(chname, @search_term))
  end

  def genre_cell_data_func(_col, renderer, _model, iter)
    genre = iter[FLD_GENRE]
    if genre.empty?
      renderer.set(text: 'n/a', foreground: 'gray')
    else
      renderer.markup = get_highlighted_markup(genre, @search_term)
    end
  end

  def listener_cell_data_func(_col, renderer, _model, iter)
    listeners = iter[FLD_LISTENER]
    if listeners < 0
      renderer.set(text: 'n/a', foreground: 'gray')
    else
      renderer.text = listeners.to_s
    end
  end

  def time_string(total_min)
    if total_min < 24 * 60
      hour = total_min / 60
      min = total_min % 60
      format('%2d:%02d', hour, min)
    else
      day = total_min / (24 * 60)
      format('%d日+', day)
    end
  end

  def time_cell_data_func(_col, renderer, _model, iter)
    time = iter[FLD_TIME]
    renderer.set(text: time_string(time),
                 foreground: time == 0 ? 'gray' : nil)
  end

  def bitrate_cell_data_func(_col, renderer, _model, iter)
    bps = iter[FLD_BITRATE]
    if bps == 0
      renderer.set(text: 'n/a', foreground: 'gray')
    elsif bps < 1000
      renderer.text = "#{bps}K"
    else
      mbps = bps.to_f / 1000
      renderer.text = format('%.2fM', mbps)
    end
  end

  def yp_cell_data_func(_col, renderer, _model, iter)
    ch = @mw_model.find_channel_by_channel_id(iter[FLD_CH_ID])
    if ch
      renderer.pixbuf = WebResource.get_pixbuf(ch.yp.favicon_url)
        .scale(16, 16, Gdk::Pixbuf::INTERP_BILINEAR)
    else
      # リストの表示とイエローページのロードが非同期だから到達するだろう。
      STDERR.puts 'Warning: failed to get YP favicon pixbuf.'
      renderer.pixbuf = QUESTION_16
    end
  end

  def detail_cell_data_func(_col, renderer, _model, iter)
    renderer.markup = get_highlighted_markup(iter[FLD_DETAIL], @search_term)
  end

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
    set_cell_renderer_font
    set_view_preferences
  end

  def set_cell_renderer_font
    @cr_name.font =
      @cr_genre.font =
      @cr_detail.font =
      @cr_listener.font =
      @cr_bitrate.font =
      @cr_time.font = ::Settings[:LIST_FONT]
  end

  GRID_LINE_CONSTANTS =
    [GRID_LINES_NONE,
     GRID_LINES_HORIZONTAL,
     GRID_LINES_VERTICAL,
     GRID_LINES_BOTH]

  def create_cell_renderers
    @cr_name	= create CellRendererText, ellipsize: Layout::ELLIPSIZE_END
    @cr_genre	= create CellRendererText, ellipsize: Layout::ELLIPSIZE_END
    @cr_detail	= create CellRendererText, ellipsize: Layout::ELLIPSIZE_END
    @cr_listener = create CellRendererText, xalign: 1
    @cr_bitrate	= create CellRendererText, xalign: 1
    @cr_yp	= create CellRendererPixbuf
    @cr_time	= create CellRendererText, xalign: 1
    set_cell_renderer_font
  end

  def create_columns
    @yp_column = TreeViewColumn.new('YP', @cr_yp)
    @name_column = TreeViewColumn.new('名前', @cr_name, text: 0)
      .set(resizable: true, min_width: 120, expand: true)
    @genre_column = TreeViewColumn.new('ジャンル', @cr_genre, text: 1)
      .set(resizable: true, min_width: 50, expand: true)
    @detail_column = TreeViewColumn.new('配信内容', @cr_detail, text: 2)
      .set(resizable: true, min_width: 240, expand: true)
    @listener_column = TreeViewColumn.new('人数', @cr_listener, text: 3)
    @time_column = TreeViewColumn.new('時間', @cr_time, text: 4)
    @bitrate_column = TreeViewColumn.new('Bps', @cr_bitrate, text: 5)
  end

  def connect_sort_changers
    [[@yp_column,       FLD_YPNAME,   SORT_ASCENDING],
     [@name_column,     FLD_CHNAME,   SORT_ASCENDING],
     [@genre_column,    FLD_GENRE,    SORT_ASCENDING],
     [@detail_column,   FLD_DETAIL,   SORT_ASCENDING],
     [@listener_column, FLD_LISTENER, SORT_DESCENDING],
     [@time_column,     FLD_TIME,     SORT_DESCENDING],
     [@bitrate_column,  FLD_BITRATE,  SORT_DESCENDING]]
      .each do |col, fldnum, order|
      col.signal_connect('clicked', &sort_changer(fldnum, order))
    end
  end

  def set_cell_data_funcs
    [[@yp_column,       @cr_yp,       :yp_cell_data_func],
     [@name_column,     @cr_name,     :name_cell_data_func],
     [@genre_column,    @cr_genre,    :genre_cell_data_func],
     [@detail_column,   @cr_detail,   :detail_cell_data_func],
     [@listener_column, @cr_listener, :listener_cell_data_func],
     [@time_column,     @cr_time,     :time_cell_data_func],
     [@bitrate_column,  @cr_bitrate,  :bitrate_cell_data_func]]
      .each do |col, cr, sym|
      col.set_cell_data_func(cr, &method(sym))
    end
  end

  def append_columns
    append_column @yp_column
    append_column @name_column
    append_column @genre_column
    append_column @detail_column
    append_column @listener_column
    append_column @time_column
    append_column @bitrate_column
  end

  def install_columns
    create_columns
    connect_sort_changers
    set_cell_data_funcs
    append_columns
    set(headers_clickable: true)
  end

  def create_list_store
    list_store = ListStore.new(*FIELD_TYPES)
    list_store.set_sort_column_id 0, SORT_ASCENDING
    list_store
  end

  def initialize(mw_model, filter_fn)
    @filter_fn = filter_fn
    @mw_model = mw_model
    @mw_model.add_observer(self, :update)

    @count = -1
    @suppress_selection_change = false

    @search_term = ''
    @list_store = create_list_store

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

    create_cell_renderers

    install_columns

    set_view_preferences

    install_context_menu

    setup_own_callbacks
  end

  def setup_own_callbacks
    signal_connect('row-activated') do |_treeview, path, _column|
      iter = model.get_iter(path)
      ch = @mw_model.find_channel_by_channel_id(iter[FLD_CH_ID])
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
    open_url(ch.contact_url) if selected_channel
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

  def create_filter(term)
    filter = TreeModelFilter.new(model)
    esc_term = Regexp.escape(regularize(term))
    filter.set_visible_func do |_model, iter|
      [FLD_CHNAME, FLD_GENRE, FLD_DETAIL]
        .any? { |fld| regularize(iter[fld]) =~ /#{esc_term}/ }
    end
    filter
  end

  def search(term)
    @search_term = term
    self.model = create_filter(term)
  end

  # 制限されたビューから全てのチャンネルのリストに戻す。
  def reset_model
    self.model = @list_store
  end

  # ch_id で判断するように変える。
  def selected_channel
    iter = selection.selected

    if iter
      @mw_model.find_channel_by_channel_id(iter[FLD_CH_ID])
    else
      nil
    end
  end

  def get_path_of_channel(ch)
    return nil unless ch
    @list_store.each do |_m, path, iter|
      return path if iter[FLD_CH_ID] == ch.channel_id
    end
    nil
  end

  # セルデータ関数とインターリーブで動くようなので、
  # モデルを切り離してから呼び出そう。
  def channel_copy(iter, ch)
    ch = ch.as Channel
    iter = iter.as TreeIter

    iter[FLD_CHNAME]   = ch.name
    iter[FLD_GENRE]    = ch.genre
    iter[FLD_DETAIL]   = ch.detail
    iter[FLD_LISTENER] = ch.listener
    iter[FLD_TIME]     = ch.time
    iter[FLD_BITRATE]  = ch.bitrate
    iter[FLD_CH_ID]    = ch.channel_id
    iter[FLD_YPNAME]   = ch.yp.name
  end

  def unselect_current_selection
    iter = selection.selected
    selection.unselect_path iter.path if iter
  end

  def select_appropriate_row
    to_be_selected = get_path_of_channel @mw_model.selected_channel
    if to_be_selected
      silently { selection.select_path to_be_selected }
    else
      silently { unselect_current_selection }
    end
  end

  def copy_from_master_table
    @list_store.clear
    match = @mw_model.master_table.select(&@filter_fn.method(:call))
    match.each do |ch|
      iter = @list_store.append
      channel_copy(iter, ch)
    end
    match.size
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

    silently { @count = copy_from_master_table }

    select_appropriate_row

    schedule_vadjustment_restore(value) if @scrolled_window

    changed
    notify_observers
  end

  def selected_channel_changed
    select_appropriate_row
  end
end
