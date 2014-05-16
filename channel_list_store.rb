# -*- coding: utf-8 -*-
# チャンネルリスト表示用データ
class ChannelListStore < Gtk::ListStore
  include Pango, Gtk, GtkHelper

  FLD_CHNAME   = 0
  FLD_GENRE    = 1
  FLD_DETAIL   = 2
  FLD_LISTENER = 3
  FLD_TIME     = 4
  FLD_BITRATE  = 5
  FLD_CH_ID    = 6
  FLD_YPNAME   = 7
  FLD_SCORE    = 8

  FIELD_TYPES = [String,	# chname
                 String,	# genre
                 String,	# detail
                 Integer,	# listener
                 Integer,	# time
                 Integer,	# bitrate
                 String,	# ch_id
                 String,	# ypname
                 Float]         # score

  def initialize(filter_fn)
    @filter_fn = filter_fn

    super(*FIELD_TYPES)

    set_sort_column_id FLD_CHNAME, SORT_ASCENDING
  end

  def replace(channel_list)
    clear
    @match = channel_list.select(&@filter_fn.method(:call))
    @match.each do |ch|
      iter = append
      channel_copy(iter, ch)
    end
  end

  def count
    @match.size
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
    iter[FLD_SCORE]    = 0.0
  end

  def channel_to_path(ch)
    return nil unless ch
    each do |_m, path, iter|
      return path if iter[FLD_CH_ID] == ch.channel_id
    end
    nil
  end

  def find_channel_by_channel_id(channel_id)
    @match.find { |ch| ch.channel_id == channel_id }
  end

  def path_to_channel(path)
    iter = get_iter(path)
    find_channel_by_channel_id(iter[FLD_CH_ID])
  end

  def iter_to_channel(iter)
    find_channel_by_channel_id(iter[FLD_CH_ID])
  end

  def create_filter(term)
    filter = TreeModelFilter.new(self)
    esc_term = Regexp.escape(regularize(term))
    filter.set_visible_func do |_model, iter|
      [FLD_CHNAME, FLD_GENRE, FLD_DETAIL]
        .any? { |fld| regularize(iter[fld]) =~ /#{esc_term}/ }
    end
    filter
  end
end
