# -*- coding: utf-8 -*-
class MainWindow < Gtk::Window
  class Notebook < Gtk::Notebook
    def initialize(model, ui)
      @ui = ui
      @model = model

      super()

      do_layout
    end

    def do_layout
      @channel_list_page = ChannelListPage.new(@model, @ui, 'すべて')
      append_page(@channel_list_page, @channel_list_page.label)

      fav_page = FavoriteListPage.new(@model, @ui)
      append_page(fav_page, fav_page.label)

      yppage = YellowPagePage.new(@model, @ui)
      append_page(yppage, yppage.label)
    end
  end
end
