# -*- coding: utf-8 -*-

# 設定を反映して有効なカラムを保待する。
class ColumnSet
  include Gtk
  include GtkHelper
  include DispatchingObserver

  attr_reader :cell_renderer_set

  ID_TO_NAME = ['YP', '名前', 'ジャンル', '配信内容', '人数', '時間', 'Bps', 'スコア', 'タイプ'].freeze
  NUM_IDS = ID_TO_NAME.size

  COL_YP       = 0
  COL_NAME     = 1
  COL_GENRE    = 2
  COL_DETAIL   = 3
  COL_LISTENER = 4
  COL_TIME     = 5
  COL_BITRATE  = 6
  COL_SCORE    = 7
  COL_TYPE     = 8

  def initialize(mw_model, list_store)
    @list_store = list_store
    @mw_model  = mw_model
    @cell_renderer_set = CellRendererSet.new(@mw_model)

    create_columns
    set_column_properties
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
    
  def each
    ::Settings[:COLUMN_PREFERENCE].each do |i|
      yield id_to_column(i)
    end
  end

  def id_to_column(id)
    [@yp_column,
     @name_column,
     @genre_column,
     @detail_column,
     @listener_column,
     @time_column,
     @bitrate_column,
     @score_column,
     @type_column][id]
  end

  def settings_changed
    cell_renderer_set.update_font
  end

  include ChannelListConstants

  def set_column_properties
    @name_column.set(resizable: true, min_width: 100, expand: true)
    @genre_column.set(resizable: true, min_width: 50, expand: true)
    @detail_column.set(resizable: true, min_width: 240, expand: true)
  end

  def create_column(column_id, attr, props = {})
    TreeViewColumn.new(ID_TO_NAME[column_id], @cell_renderer_set.send(attr), props)
  end

  def create_columns
    @yp_column       = create_column COL_YP,       :yp
    @name_column     = create_column COL_NAME  ,   :name,     text: FLD_CHNAME
    @genre_column    = create_column COL_GENRE,    :genre,    text: FLD_GENRE
    @detail_column   = create_column COL_DETAIL,   :detail,   text: FLD_DETAIL
    @listener_column = create_column COL_LISTENER, :listener, text: FLD_LISTENER
    @time_column     = create_column COL_TIME,     :time,     text: FLD_TIME
    @bitrate_column  = create_column COL_BITRATE,  :bitrate,  text: FLD_BITRATE
    @score_column    = create_column COL_SCORE,    :score,    text: FLD_SCORE
    @type_column     = create_column COL_TYPE,     :type,     text: FLD_TYPE
  end

  def connect_sort_changers
    [[@yp_column,       FLD_YPNAME,   SORT_ASCENDING],
     [@name_column,     FLD_CHNAME,   SORT_ASCENDING],
     [@genre_column,    FLD_GENRE,    SORT_ASCENDING],
     [@detail_column,   FLD_DETAIL,   SORT_ASCENDING],
     [@listener_column, FLD_LISTENER, SORT_DESCENDING],
     [@time_column,     FLD_TIME,     SORT_DESCENDING],
     [@bitrate_column,  FLD_BITRATE,  SORT_DESCENDING],
     [@score_column,    FLD_SCORE,    SORT_ASCENDING],
     [@type_column,     FLD_TYPE,     SORT_ASCENDING]]
      .each do |col, fldnum, order|
      col.signal_connect('clicked', &sort_changer(fldnum, order))
    end
  end

  def set_cell_data_funcs
    [[@yp_column,       @cell_renderer_set.yp,       :yp_cell_data_func],
     [@name_column,     @cell_renderer_set.name,     :name_cell_data_func],
     [@genre_column,    @cell_renderer_set.genre,    :genre_cell_data_func],
     [@detail_column,   @cell_renderer_set.detail,   :detail_cell_data_func],
     [@listener_column, @cell_renderer_set.listener, :listener_cell_data_func],
     [@time_column,     @cell_renderer_set.time,     :time_cell_data_func],
     [@bitrate_column,  @cell_renderer_set.bitrate,  :bitrate_cell_data_func],
     [@score_column,    @cell_renderer_set.score,    :score_cell_data_func]]
      .each do |col, cr, sym|
      col.set_cell_data_func(cr, &@cell_renderer_set.method(sym))
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
