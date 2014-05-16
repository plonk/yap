# -*- coding: utf-8 -*-
class ColumnSet
  include Gtk
  include GtkHelper

  attr_reader :cell_renderer

  def initialize(mw_model, list_store)
    @list_store = list_store
    @mw_model  = mw_model
    @cell_renderer = CellRendererSet.new(@mw_model)

    create_columns
    connect_sort_changers
    set_cell_data_funcs

    setup_observing_relationship
  end

  def setup_observing_relationship
    @mw_model.add_observer(self)
  end

  def finalize
    @mw_model.delete_observer(self)
  end
    
  def update(message, *args)
    if self.respond_to? message
      Gtk.queue do
        __send__(message, *args)
      end
    end
  end

  def each
    [@yp_column,
     @name_column,
     @genre_column,
     @detail_column,
     @listener_column,
     @time_column,
     @bitrate_column].each do |col|
      yield(col)
    end
  end

  def settings_changed
    @column_set.cell_renderer.set_cell_renderer_font
  end

  def create_columns
    @yp_column       = TreeViewColumn.new('YP', @cell_renderer.yp)
    @name_column     = TreeViewColumn.new('名前', @cell_renderer.name, text: 0)
      .set(resizable: true, min_width: 100, expand: true)
    @genre_column    = TreeViewColumn.new('ジャンル', @cell_renderer.genre, text: 1)
      .set(resizable: true, min_width: 50, expand: true)
    @detail_column   = TreeViewColumn.new('配信内容', @cell_renderer.detail, text: 2)
      .set(resizable: true, min_width: 240, expand: true)
    @listener_column = TreeViewColumn.new('人数', @cell_renderer.listener, text: 3)
    @time_column     = TreeViewColumn.new('時間', @cell_renderer.time, text: 4)
    @bitrate_column  = TreeViewColumn.new('Bps', @cell_renderer.bitrate, text: 5)
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
    [[@yp_column,       @cell_renderer.yp,       :yp_cell_data_func],
     [@name_column,     @cell_renderer.name,     :name_cell_data_func],
     [@genre_column,    @cell_renderer.genre,    :genre_cell_data_func],
     [@detail_column,   @cell_renderer.detail,   :detail_cell_data_func],
     [@listener_column, @cell_renderer.listener, :listener_cell_data_func],
     [@time_column,     @cell_renderer.time,     :time_cell_data_func],
     [@bitrate_column,  @cell_renderer.bitrate,  :bitrate_cell_data_func]]
      .each do |col, cr, sym|
      col.set_cell_data_func(cr, &@cell_renderer.method(sym))
    end
  end

  # ソートするカラムを column_id に切り替える手続きオブジェクトを返す。
  def sort_changer(column_id, order)
    fail ArgumentError, 'unknown sort order' unless
      [SORT_ASCENDING, SORT_DESCENDING].include? order
    lambda do |_tree_view_column|
      @list_store.set_sort_column_id column_id, order
    end
  end
end
