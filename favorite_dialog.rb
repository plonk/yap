# -*- coding: utf-8 -*-
require 'gtk2'
require_relative 'utility'
require_relative 'line_prompt'

class FavoriteDialog < Gtk::Dialog
  include Gtk
  include GtkHelper
  attr_reader :list

  def initialize(parent_window, list)
    super("お気に入りの整理", parent_window, Dialog::MODAL)

    @list = list

    set_default_size(512, 384)
    add_button(Stock::OK, Dialog::RESPONSE_OK)
    add_button(Stock::CANCEL, Dialog::RESPONSE_CANCEL)

    self.vbox.spacing = 10

    model = ListStore.new(String)

    col = TreeViewColumn.new("名前", CellRendererText.new, text: 0)

    @treeview = create(TreeView, model,
                headers_visible: false)
    @treeview.append_column(col)

    list.each(&method(:append_item))

    sw = create(ScrolledWindow,
                hscrollbar_policy: POLICY_AUTOMATIC,
                vscrollbar_policy: POLICY_ALWAYS)
    sw.add @treeview

    vbox.pack_start(sw, true)

    button_hbox = create(HButtonBox, layout_style: ButtonBox::END, spacing: 10)
    add_button = create(Button, "追加", width_request: 60,
                        on_clicked: proc {
                          dialog = LinePrompt.new("お気に入りのチャンネルを追加", self)
                          dialog.show_all
                          dialog.run do |response|
                            if response == Dialog::RESPONSE_OK
                              @list.push(dialog.text)
                              append_item(dialog.text)
                            end
                          end
                          dialog.destroy
                        })
    del_button = create(Button, "削除", width_request: 60,
                        on_clicked: proc {
                          path, column = @treeview.cursor
                          if path 
                            iter = @treeview.model.get_iter(path)
                            @list.delete(iter[0])
                            @treeview.model.remove(iter)
                          end
                        })
    button_hbox.pack_end(add_button, false)
    button_hbox.pack_end(del_button, false)
    vbox.pack_start(button_hbox, false)
    vbox.pack_start(HSeparator.new, false)
  end

  def append_item str
    iter = @treeview.model.append
    iter[0] = str
  end
end
