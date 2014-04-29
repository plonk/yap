# -*- coding: utf-8 -*-

class ChannelDBDialog < Gtk::Dialog
  include Gtk

  def initialize
    super("チャンネルDB", $window, Dialog::MODAL)
    set_default_size(512, 512)

    top_hbox = HBox.new
    @default_text = "過去に見かけたことのあるすべてのチャンネルです。#{$CDB.keys.size} 個あります。"
    @explanation = Label.new(@default_text)
    top_hbox.pack_start(@explanation, true)
    @search_field = Entry.new
    top_hbox.pack_start(@search_field, false)
    @clear_button = Button.new(" ☓ ")
    @clear_button.tooltip_text = "クリアして検索を終了"
    top_hbox.pack_start(@clear_button, false)

    @search_term = ""
    @clear_button.signal_connect("clicked") do 
      @explanation.text = @default_text
      @search_field.text = ""
      @search_term = ""
      @model.clear
      append_all_channels
    end
    @search_field.signal_connect("activate") do
      term = @search_term = @search_field.text
      if term == ""
        @clear_button.activate
        next
      end
      @model.clear
      regex = /#{regularize(term)}/ #XXX should be escaped
      nrows = 0
      $CDB.each_pair do |key, value|
        key.force_encoding("utf-8")
        if regularize(key) =~ regex
          time, url = value.parse_csv
          iter = @model.append
          iter[0] = key
          iter[1] = time.to_i
          p @search_field.text
          nrows += 1
        end
      end
          
      if nrows == 0
        @explanation.text = "\"#{term}\" を含むチャンネルはありません。"
      else
        @explanation.text = "#{term} を含むチャンネル #{nrows} 個。"
      end
    end
    

    vbox.pack_start top_hbox, false

    @today = Time.now

    add_button(Stock::OK, Dialog::RESPONSE_OK)

    signal_connect("response") do |d, res|
      destroy
    end

    @model = ListStore.new(String, Integer)
    @scrolled_window = ScrolledWindow.new
    @scrolled_window.set_policy(POLICY_AUTOMATIC, POLICY_ALWAYS)

    @treeview = TreeView.new(@model)
    @scrolled_window.add @treeview

    cr_name = CellRendererText.new()
    cr_date = CellRendererText.new()

    col_name = TreeViewColumn.new("名前", cr_name, :text=>0)
    col_date = TreeViewColumn.new("最後に見かけた", cr_date)

    col_name.set_cell_data_func(cr_name) do |col, renderer, model, iter|
      renderer.markup = get_highlighted_markup(iter[0], @search_term)
    end

    col_date.set_cell_data_func(cr_date) do |col, renderer, model, iter|
      time, url = $CDB[iter[0]].parse_csv
      unix_time = time.to_i
      t = Time.at(unix_time)
      text = nil
      if @today.year == t.year
        text = case t.yday
               when @today.yday
                 "今日"
               when @today.yday-1
                 "昨日"
               when @today.yday-2
                 "おととい"
               when t.yday-3
                 "3日前"
               else
                 t.strftime("%m月%d日")
               end
      else
        text =  t.strftime("%y年%m月")#%d日")
      end

      renderer.text = text
    end

    @treeview.append_column(col_name)
    @treeview.append_column(col_date)

    @treeview.signal_connect("cursor-changed") do |t|
      path, column = t.cursor
      return unless path

      iter = @model.get_iter(path)
      chname = iter[0]
      time, url = $CDB[chname].parse_csv
      @link_button.uri = url
      @link_button.child.text = url
      @link_button.tooltip_text = "(ページタイトル取得中...)"
      Thread.start do 
        t = get_page_title(url)
        Gtk.queue do
          if @link_button.uri == url # cursor is still not changed
            if t == nil
              @link_button.tooltip_text = "(取得に失敗しました)"
            else
              @link_button.tooltip_text = t
            end
          end
        end
      end
    end

    append_all_channels

    @model.set_sort_column_id(0, SORT_ASCENDING)

    @treeview.enable_search = true
    @treeview.search_column = 0
    @treeview.set_search_entry(@search_field)
    

    @link_button = LinkButton.new("", "")
    @link_button.xalign = 0
    @link_button.child.ellipsize = Pango::Layout::ELLIPSIZE_END
    @link_button.signal_connect("clicked") do
      p @link_button.uri
      system("start", @link_button.uri)
      true # これ要るん？
    end

    link_hbox = HBox.new
    link_hbox.pack_start Label.new("掲示板:"), false
    link_hbox.pack_start @link_button, true

    vbox.pack_start(@scrolled_window)
    vbox.pack_start link_hbox, false
  end

  def append_all_channels
    keys = $CDB.keys
    keys.each {|x| x.force_encoding("utf-8")}
    keys.each do |k|
      iter = @model.append
      iter[0] = k
      iter[1] = $CDB[k].to_i
    end
  end
end
