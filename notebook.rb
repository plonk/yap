# -*- coding: utf-8 -*-
class MainWindow < Gtk::Window
  class Notebook < Gtk::Notebook
    def initialize(model)
      @model = model
      super()

      do_layout
    end

    def do_layout
      @channel_list_page = ChannelListPage.new(@model, 'すべて')
      append_page(@channel_list_page, @channel_list_page.label)

      fav_page = ChannelListPage.new(@model, 'お気に入り',
                                     proc do |ch|
                                       @model.favorites.include? ch.name
                                     end)
      append_page(fav_page, fav_page.label)
    end
  end
end

