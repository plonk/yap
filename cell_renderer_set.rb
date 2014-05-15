# -*- coding: utf-8 -*-
class CellRendererSet
  include Pango, Gtk, GtkHelper

  attr_reader :name, :yp, :genre, :detail, :listener
  attr_reader :time, :bitrate
  attr_accessor :highlight_term

  TARGET_NAME_CELL_WIDTH = 16.0

  def initialize(mw_model)
    @mw_model = mw_model
    @highlight_term = ''
    create_cell_renderers
  end

  def set_font_size(chname, font)
    half_widths = measure_width(chname)

    if half_widths > TARGET_NAME_CELL_WIDTH
      factor = TARGET_NAME_CELL_WIDTH / half_widths
      font.size = [10 * factor, 8].max * 1000
    end
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
    chname = iter[ChannelListStore::FLD_CHNAME]

    set_font_size(chname, renderer.font_desc)
    fg, bg, weight = name_cell_font_style(chname)
    renderer.set(foreground: fg, background: bg)
    if weight
      renderer.set(weight: weight)
    else
      base_font = Pango::FontDescription.new(::Settings[:LIST_FONT])
      renderer.set(weight: base_font.weight)
    end
    renderer.set_property('markup',
                          get_highlighted_markup(chname, @highlight_term))
  end

  def genre_cell_data_func(_col, renderer, _model, iter)
    genre = iter[ChannelListStore::FLD_GENRE]
    if genre.empty?
      renderer.set(text: 'n/a', foreground: 'gray')
    else
      renderer.markup = get_highlighted_markup(genre, @highlight_term)
    end
  end

  def listener_cell_data_func(_col, renderer, _model, iter)
    listeners = iter[ChannelListStore::FLD_LISTENER]
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
    time = iter[ChannelListStore::FLD_TIME]
    renderer.set(text: time_string(time),
                 foreground: time == 0 ? 'gray' : nil)
  end

  def bitrate_cell_data_func(_col, renderer, _model, iter)
    bps = iter[ChannelListStore::FLD_BITRATE]
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
    channel_id = iter[ChannelListStore::FLD_CH_ID]
    ch = @mw_model.find_channel_by_channel_id(channel_id)
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
    detail = iter[ChannelListStore::FLD_DETAIL]
    renderer.markup = get_highlighted_markup(detail, @highlight_term)
  end

  def set_cell_renderer_font
    @name.font =
      @genre.font =
      @detail.font =
      @listener.font =
      @bitrate.font =
      @time.font = ::Settings[:LIST_FONT]
  end

  def create_cell_renderers
    @name	= create CellRendererText, ellipsize: Layout::ELLIPSIZE_END
    @genre	= create CellRendererText, ellipsize: Layout::ELLIPSIZE_END
    @detail	= create CellRendererText, ellipsize: Layout::ELLIPSIZE_END
    @listener = create CellRendererText, xalign: 1
    @bitrate	= create CellRendererText, xalign: 1
    @yp	= create CellRendererPixbuf
    @time	= create CellRendererText, xalign: 1
    set_cell_renderer_font
  end
end
