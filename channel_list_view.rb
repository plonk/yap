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

  # FIELDS:      chname,  genre, detail, listener,   time, bitrate,  ch_id, ypname
  FIELD_TYPES = [String, String, String, Integer, Integer, Integer, String, String]

  def open_url(url)
    Environment.open(url)
  end

  TARGET_NAME_CELL_WIDTH = 16.0

  def name_cell_data_func col, renderer, model, iter
    base_font = Pango::FontDescription.new(::Settings[:LIST_FONT])

    half_widths = measure_width(iter[0])
    if half_widths > TARGET_NAME_CELL_WIDTH
      factor = TARGET_NAME_CELL_WIDTH / half_widths
      base_font.size = [10*factor,8].max * 1000
    end
    renderer.font = base_font
    if @mw_model.favorites.include? iter[0]
      renderer.background = "#FFBBBB" # pink if favorite
      renderer.weight = WEIGHT_BOLD
      renderer.background_set = true
    elsif iter[0] =~ /\(要帯域チェック\)$/
      renderer.background = "yellow"
      renderer.background_set = true
    else
      renderer.foreground_set = false
      renderer.background_set = false
      renderer.weight = WEIGHT_NORMAL
    end
    renderer.set_property("markup", get_highlighted_markup(iter[0], @search_term))
  end

  def genre_cell_data_func col, renderer, model, iter
    renderer.foreground_set = false
    genre = iter[1]
    if genre == ""
      renderer.text = "n/a"
      renderer.foreground = "gray"
    else
      renderer.markup = get_highlighted_markup(genre, @search_term)
    end
  end

  def listener_cell_data_func col, renderer, model, iter
    renderer.weight = WEIGHT_NORMAL
    renderer.foreground_set = false
    i = iter[3]
    if i < 0
      renderer.text = "n/a"
      renderer.foreground = "gray"
    else
      renderer.text = i.to_s
    end
  end

  def time_cell_data_func col, renderer, model, iter
    renderer.foreground_set = false
    i = iter[4]
    if i < 24 * 60
      hour = i / 60
      min = i % 60
      renderer.text = sprintf("%2d:%02d", hour, min)
      renderer.foreground = "gray" if hour == 0  and  min == 0
    else
      if false
        day = i.to_f / (24*60)
        renderer.text = sprintf("%.1f日", day)
      else
        day = i / (24*60)
        renderer.text = sprintf("%d日+", day)
      end
    end
  end

  def bitrate_cell_data_func col, renderer, model, iter
    renderer.weight = WEIGHT_NORMAL
    renderer.foreground_set = false
    bps = iter[5]
    if bps == 0
      renderer.text = "n/a"
      renderer.foreground = "gray"
    elsif bps < 1000
      renderer.text = "#{bps}K"
    else
      m = bps.to_f / 1000
      renderer.text = sprintf("%.2fM", m)
    end
  end

  def yp_cell_data_func col, renderer, model, iter
    ch = @mw_model.find_channel_by_channel_id(iter[FLD_CH_ID])
    if ch
      renderer.pixbuf = WebResource.get_pixbuf(ch.yp.favicon_url)
        .scale(16, 16, Gdk::Pixbuf::INTERP_BILINEAR)
    else
      # リストの表示とイエローページのロードが非同期だから到達するだろう。
      renderer.pixbuf = QUESTION_16
    end
  end

  def detail_cell_data_func col, renderer, model, iter
    renderer.markup = get_highlighted_markup(iter[2], @search_term)
  end

  # ソートするカラムを column_id に切り替える手続きオブジェクトを返す。
  def sort_changer(column_id, order)
    raise ArgumentError, "unknown sort order" unless [SORT_ASCENDING, SORT_DESCENDING].include? order
    lambda do |tree_view_column|
      @list_store.set_sort_column_id column_id, order
    end
  end

  def update message, *args
    if self.respond_to? message
      Gtk.queue do 
        self.__send__(message, *args)
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
    @cr_name.font =
      @cr_genre.font =
      @cr_detail.font =
      @cr_listener.font =
      @cr_bitrate.font =
      @cr_time.font = ::Settings[:LIST_FONT]

    set_view_preferences
  end

  GRID_LINE_CONSTANTS = [GRID_LINES_NONE, GRID_LINES_HORIZONTAL, GRID_LINES_VERTICAL, GRID_LINES_BOTH]

  def initialize(mw_model, func)
    @func = func
    @mw_model = mw_model
    @mw_model.add_observer(self, :update)
    @count = -1
    @suppress_selection_change = false

    @search_term = ""
    @list_store = ListStore.new(*FIELD_TYPES)
    super(@list_store)
    selection.mode = SELECTION_BROWSE


    # セルレンダラーの設定
    @cr_name	= create CellRendererText, font: ::Settings[:LIST_FONT], ellipsize: Layout::ELLIPSIZE_END
    @cr_genre	= create CellRendererText, font: ::Settings[:LIST_FONT], ellipsize: Layout::ELLIPSIZE_END
    @cr_detail	= create CellRendererText, font: ::Settings[:LIST_FONT], ellipsize: Layout::ELLIPSIZE_END
    @cr_listener= create CellRendererText, font: ::Settings[:LIST_FONT], xalign: 1
    @cr_bitrate	= create CellRendererText, font: ::Settings[:LIST_FONT], xalign: 1
    @cr_yp	= create CellRendererPixbuf
    @cr_time	= create CellRendererText, font: ::Settings[:LIST_FONT], xalign: 1

    @yp_column = TreeViewColumn.new("YP", @cr_yp)
    @yp_column.signal_connect("clicked", &sort_changer(FLD_YPNAME, SORT_ASCENDING))
    @yp_column.set_cell_data_func(@cr_yp, &method(:yp_cell_data_func))
    append_column @yp_column

    @name_column = TreeViewColumn.new("名前", @cr_name, text: 0)
      .set(resizable: true, min_width: 120, expand: true)
    @name_column.signal_connect("clicked", &sort_changer(0, SORT_ASCENDING))
    @name_column.set_cell_data_func(@cr_name, &method(:name_cell_data_func))
    append_column @name_column

    @genre_column = TreeViewColumn.new("ジャンル", @cr_genre, text: 1)
      .set(resizable: true, min_width: 50, expand: true)
    @genre_column.signal_connect("clicked", &sort_changer(1, SORT_ASCENDING))
    @genre_column.set_cell_data_func(@cr_genre, &method(:genre_cell_data_func))
    append_column @genre_column

    @detail_column = TreeViewColumn.new("配信内容", @cr_detail, text: 2)
      .set(resizable: true, min_width: 240, expand: true)
    @detail_column.signal_connect("clicked", &sort_changer(2, SORT_ASCENDING))
    @detail_column.set_cell_data_func(@cr_detail, &method(:detail_cell_data_func))
    append_column @detail_column

    @listener_column = TreeViewColumn.new("人数", @cr_listener, text: 3)
    @listener_column.signal_connect("clicked", &sort_changer(3, SORT_DESCENDING))
    @listener_column.set_cell_data_func(@cr_listener, &method(:listener_cell_data_func))
    append_column @listener_column

    @time_column = TreeViewColumn.new("時間", @cr_time, :text=>4)
    @time_column.signal_connect("clicked", &sort_changer(4, SORT_DESCENDING))
    @time_column.set_cell_data_func(@cr_time, &method(:time_cell_data_func))
    append_column @time_column

    @bitrate_column = TreeViewColumn.new("Bps", @cr_bitrate, text: 5)
    @bitrate_column.signal_connect("clicked", &sort_changer(5, SORT_DESCENDING))
    @bitrate_column.set_cell_data_func(@cr_bitrate, &method(:bitrate_cell_data_func))
    append_column @bitrate_column

    set(headers_clickable: true)

    set_view_preferences()

    @list_store.set_sort_column_id 0, SORT_ASCENDING

    @context_menu = ContextMenu.new(@mw_model)

    self.events = Gdk::Event::BUTTON_PRESS_MASK
    signal_connect("button_press_event", &method(:on_button_press_event))

    signal_connect("row-activated") do |treeview, path, column|
      iter = model.get_iter(path)
      ch = @mw_model.find_channel_by_channel_id(iter[FLD_CH_ID])
      fail unless ch
      if ch.playable?
        @mw_model.play(ch)
      end
    end

    # 行が選択された時に実行される
    selection.signal_connect("changed") do
      @mw_model.select_channel(get_selected_channel) unless @suppress_selection_change
    end

    refresh
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

  def on_button_press_event w, event
    # なんで Button press 以外のイベントが来るんだろう？
    unless event.event_type == Gdk::Event::BUTTON_PRESS
      STDERR.puts event.inspect 
    end
    if event.button == 3
      if ch = get_selected_channel
        @context_menu.associate(ch)
        @context_menu.show_all
        @context_menu.popup(nil, nil, event.button, event.time)
      end
      true
    elsif event.button == 2
      # 中クリックの位置によらず、既に選択されている行のコンタクト
      # URLが開かれるのは問題。
      if ch = get_selected_channel
        open_url(ch.contact_url)
      end
      true
    else
      false
    end
  end

  def search(term)
    @search_term = term
    search_result = TreeModelFilter.new(model)
    esc_term = Regexp.escape(regularize(term))
    search_result.set_visible_func do |model, iter|
      if [FLD_CHNAME,
          FLD_GENRE,
          FLD_DETAIL]
          .any? { |fld| regularize(iter[fld]) =~ /#{esc_term}/ }
        true
      else
        false
      end
    end
    self.model = search_result
  end

  # 制限されたビューから全てのチャンネルのリストに戻す。
  def reset_model
    self.model = @list_store
  end

  # ch_id で判断するように変える。
  def get_selected_channel
    iter = selection.selected

    if iter
      @mw_model.find_channel_by_channel_id(iter[FLD_CH_ID])
    else
      nil
    end
  end

  def get_path_of_channel(ch)
    @list_store.each do |m, path, iter|
      if iter[FLD_CH_ID] == ch.channel_id
        return path
      end
    end
    return nil
  end

  # セルデータ関数とインターリーブで動くようなので、
  # モデルを切り離してから呼び出そう。
  def channel_copy iter, ch
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

  def select_appropriate_row
    ch = @mw_model.selected_channel
    if ch
      to_be_selected = get_path_of_channel  ch
    end
    if to_be_selected==nil
      iter = self.selection.selected
      if iter
        silently do
          self.selection.unselect_path iter.path 
        end
      end
    else
      silently do
        self.selection.select_path to_be_selected
      end
    end
  end

  def refresh
    if @scrolled_window
      value = @scrolled_window.vadjustment.value
    end

    silently do 
      @list_store.clear
      match = @mw_model.master_table.select(&@func.method(:call))
      @count = match.size 
      match.each do |ch|
        iter = @list_store.append
        channel_copy(iter, ch)
      end
    end

    select_appropriate_row

    if @scrolled_window
      Thread.new do
        sleep 0.5
        Gtk.queue do @scrolled_window.vadjustment.value = [@scrolled_window.vadjustment.upper, value].min end
      end
    end
    changed
    notify_observers
  end

  def selected_channel_changed
    select_appropriate_row
  end
end
