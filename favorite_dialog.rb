# -*- coding: utf-8 -*-
require 'gtk2'
require_relative 'utility'
require_relative 'line_prompt'
require_relative 'gtk_helper'

# お気に入り編集用ダイアログ
class FavoriteDialog < Gtk::Dialog
  include Gtk, GtkHelper
  attr_reader :list

  COL_NAME = 0

  def initialize(parent_window, list)
    @list = list
    super('お気に入りの整理', parent_window, MODAL)

    do_layout
    @list.each(&method(:append_item))
  end

  def do_layout
    set_default_size(512, 384)
    vbox.spacing = 10

    create(ScrolledWindow,
           hscrollbar_policy: POLICY_AUTOMATIC,
           vscrollbar_policy: POLICY_ALWAYS) do |sw|
      @treeview = create_treeview
      sw.add @treeview
      vbox.pack_start(sw, true)
    end

    button_hbox = create(HButtonBox, layout_style: ButtonBox::END, spacing: 10)
    add_button = create(Button, '追加',
                        width_request: 60,
                        on_clicked: proc { open_add_dialog } )
    del_button = create(Button, '削除',
                        width_request: 60,
                        on_clicked: proc { open_del_dialog } )
    button_hbox.pack_end(add_button, false)
    button_hbox.pack_end(del_button, false)
    vbox.pack_start(button_hbox, false)
    vbox.pack_start(HSeparator.new, false)

    add_dialog_buttons
  end

  def create_treeview
    create(TreeView, ListStore.new(String),
           headers_visible: false) do |treeview|
      column = TreeViewColumn.new('名前', CellRendererText.new, text: COL_NAME)
      treeview.append_column(column)
    end
  end

  def add_dialog_buttons
    add_button(Stock::CANCEL, RESPONSE_CANCEL)
    add_button(Stock::OK, RESPONSE_OK)

    set_alternative_button_order [RESPONSE_OK, RESPONSE_CANCEL]
  end

  def open_add_dialog
    dialog = LinePrompt.new('お気に入りのチャンネルを追加', self)
    dialog.show_all
    dialog.run do |response|
      if response == RESPONSE_OK
        @list.push(dialog.text)
        append_item(dialog.text)
      end
    end
    dialog.destroy
  end

  def open_del_dialog
    path, _column = @treeview.cursor
    return unless path

    iter = @treeview.model.get_iter(path)
    @list.delete(iter[COL_NAME])
    @treeview.model.remove(iter)
  end

  def append_item(str)
    iter = @treeview.model.append
    iter[COL_NAME] = str
  end
end
