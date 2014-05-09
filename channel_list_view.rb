# -*- coding: utf-8 -*-
require_relative 'gtk_helper'

class ChannelListView < Gtk::TreeView
end

require_relative 'clv_context_menu'

class ChannelListView < Gtk::TreeView
  include Pango, Gtk, GtkHelper

  FLD_CHNAME   = 0
  FLD_GENRE    = 1
  FLD_DETAIL   = 2
  FLD_LISTENER = 3
  FLD_TIME     = 4
  FLD_BITRATE  = 5
  FLD_HASH     = 6

  # FIELDS:      chname,  genre, detail, listener,   time, bitrate,   hash
  FIELD_TYPES = [String, String, String, Integer, Integer, Integer, String]

  def open_url(url)
    Environment.open(url)
  end

  def name_cell_data_func col, renderer, model, iter
    width = measure_width(iter[0])
    if width > 16
      factor = (16.0 / width)
      if factor < 5
        factor = 0.8
      end
      renderer.font = "Meiryo UI %.1f" % (10 * factor)
    else
      renderer.font = "Meiryo 10"
    end
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
    renderer.set_property("markup", get_highlighted_markup(iter[0], @mw_model.search_term))
  end

  def genre_cell_data_func col, renderer, model, iter
    renderer.foreground_set = false
    genre = iter[1]
    if genre == ""
      renderer.text = "n/a"
      renderer.foreground = "gray"
    else
      renderer.markup = get_highlighted_markup(genre, @mw_model.search_term)
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
    ch = @mw_model.find_channel_by_hash(iter[FLD_HASH].to_i(16))
    if ch
      renderer.pixbuf = get_pixbuf_from_url(ch.yp.favicon_url)
        .scale(16, 16, Gdk::Pixbuf::INTERP_BILINEAR)
    else
      # リストの表示とイエローページのロードが非同期だから到達するだろう。
      renderer.pixbuf = QUESTION_16
    end
  end

  def detail_cell_data_func col, renderer, model, iter
    renderer.markup = get_highlighted_markup(iter[2], @mw_model.search_term)
  end

  # ソートするカラムを column_id に切り替える手続きオブジェクトを返す。
  def sort_changer(column_id, order)
    raise ArgumentError, "unknown sort order" unless [SORT_ASCENDING, SORT_DESCENDING].include? order
    lambda do |tree_view_column|
      @list_store.set_sort_column_id column_id, order
    end
  end

  def initialize(mw_model)
    @mw_model = mw_model
    @list_store = ListStore.new(*FIELD_TYPES)
    super(@list_store)

    # セルレンダラーの設定
    cr_name	= create CellRendererText, font: "10",          ellipsize: Layout::ELLIPSIZE_END
    cr_genre	= create CellRendererText, font: "Meiryo UI",   ellipsize: Layout::ELLIPSIZE_END
    cr_detail	= create CellRendererText, font: "Meiryo UI 9", ellipsize: Layout::ELLIPSIZE_END
    cr_listener	= create CellRendererText, xalign: 1
    cr_bitrate	= create CellRendererText, xalign: 1
    cr_yp	= create CellRendererPixbuf
    cr_time	= create CellRendererText, xalign: 1

    @yp_column = TreeViewColumn.new("YP", cr_yp)
    @yp_column.set_cell_data_func(cr_yp, &method(:yp_cell_data_func))
    append_column @yp_column

    @name_column = TreeViewColumn.new("名前", cr_name, text: 0)
    @name_column.resizable = true
    @name_column.min_width = 150
    @name_column.signal_connect("clicked", &sort_changer(0, SORT_ASCENDING))
    @name_column.set_cell_data_func(cr_name, &method(:name_cell_data_func))
    append_column @name_column

    @genre_column = TreeViewColumn.new("ジャンル", cr_genre, text: 1)
    @genre_column.resizable = true
    @genre_column.min_width = 70
    @genre_column.signal_connect("clicked", &sort_changer(1, SORT_ASCENDING))
    @genre_column.set_cell_data_func(cr_genre, &method(:genre_cell_data_func))
    append_column @genre_column

    @detail_column = TreeViewColumn.new("配信内容", cr_detail, text: 2)
    @detail_column.resizable = true
    @detail_column.min_width = 240
    @detail_column.signal_connect("clicked", &sort_changer(2, SORT_ASCENDING))
    @detail_column.set_cell_data_func(cr_detail, &method(:detail_cell_data_func))
    append_column @detail_column

    @listener_column = TreeViewColumn.new("人数", cr_listener, text: 3)
    @listener_column.signal_connect("clicked", &sort_changer(3, SORT_DESCENDING))
    @listener_column.set_cell_data_func(cr_listener, &method(:listener_cell_data_func))
    append_column @listener_column

    @time_column = TreeViewColumn.new("時間", cr_time, :text=>4)
    @time_column.signal_connect("clicked", &sort_changer(4, SORT_DESCENDING))
    @time_column.set_cell_data_func(cr_time, &method(:time_cell_data_func))
    append_column @time_column

    @bitrate_column = TreeViewColumn.new("Bps", cr_bitrate, text: 5)
    @bitrate_column.signal_connect("clicked", &sort_changer(5, SORT_DESCENDING))
    @bitrate_column.set_cell_data_func(cr_bitrate, &method(:bitrate_cell_data_func))
    append_column @bitrate_column

    self.headers_clickable = true
    self.enable_grid_lines = GRID_LINES_HORIZONTAL
    @list_store.set_sort_column_id 0, SORT_ASCENDING

    @context_menu = ContextMenu.new(@mw_model)

    self.events = Gdk::Event::BUTTON_PRESS_MASK
    signal_connect("button_press_event", &method(:on_button_press_event))

    signal_connect("row-activated") do |treeview, path, column|
      iter = model.get_iter(path)
      ch = @mw_model.get_channel(iter[FLD_CHNAME])
      if ch.playable?
        @mw_model.play(ch)
      end
    end

    # 行が選択された時に実行される
    signal_connect("cursor-changed") do |treeview|
      @mw_model.select_channel(get_selected_channel)
    end
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
    search_result = TreeModelFilter.new(model)
    esc_term = Regexp.escape(regularize(term))
    search_result.set_visible_func do |model, iter|
      if [iter[FLD_CHNAME],
          iter[FLD_GENRE],
          iter[FLD_DETAIL]].include? nil
        next false
      end
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

  # hash で判断するように変える。
  def get_selected_channel
    path, column = cursor

    if path
      iter = self.model.get_iter(path)
      @mw_model.get_channel(iter[FLD_CHNAME])
    else
      nil
    end
  end

  # 一致を調べるべきフィールドが違うかもしれない。
  def get_path_of_channel(ch)
    @list_store.each do |m, path, iter|
      if iter[FLD_CHNAME] == ch.name
        return path
      end
    end
    return nil
  end

  def channel_copy iter, ch
    ch = ch.as Channel
    iter = iter.as TreeIter

    iter[FLD_CHNAME]   = ch.name
    iter[FLD_GENRE]    = ch.genre
    iter[FLD_DETAIL]   = ch.detail
    iter[FLD_LISTENER] = ch.listener
    iter[FLD_TIME]     = ch.time
    iter[FLD_BITRATE]  = ch.bitrate
    iter[FLD_HASH]     = ch.hash.to_s(16)
  end

  # チャンネルリストとListStoreをマージする
  def refresh
    finished_refs = []

    model.each do |model, path, iter|
      if @mw_model.finished.any? { |ch| ch.hash.to_s(16) == iter[FLD_HASH] }
        finished_refs << TreeRowReference.new(model, path)
      else
        match = @mw_model.master_table.select { |ch| ch.hash.to_s(16) == iter[FLD_HASH] }
        fail "logic error" unless match.size == 1
        channel_copy(iter, match.first)
      end
    end

    finished_refs.each do |ref|
      model.remove model.get_iter(ref.path)
    end

    @mw_model.just_began.each do |ch|
      iter = model.append
      channel_copy(iter, ch)
    end
  end
end
