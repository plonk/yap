# -*- coding: utf-8 -*-
require 'observer'

# オブジェクトのリストを受け取って、そのプロパティを表で表示したり、
# リストを編集するためのウィジェット。
class ObjectList < Gtk::ScrolledWindow
  include Gtk, GtkHelper, Observable

  attr_reader :treeview
  attr_reader :selected

  # 上矢印が昇順がいい。
  UP_ARROW = Gtk::SORT_DESCENDING
  DOWN_ARROW = Gtk::SORT_ASCENDING

  FLD_ID = 0

  def initialize(headers, reader_list, writer_list, constructor = nil)
    super()

    @objects = []
    @headers = headers
    @reader_list = reader_list.map(&:to_proc)
    @writer_list = writer_list.map { |writer| writer ? writer.to_proc : nil }
    @constructor = constructor

    do_layout
  end

  def do_layout
    self.hscrollbar_policy = POLICY_AUTOMATIC

    types = [String] * @reader_list.size
    @list_store = ListStore.new(*[String] + types)
    @treeview = create(TreeView, @list_store)

    install_columns(@headers)

    @treeview.search_column = 1
    @treeview.selection.signal_connect('changed', &method(:on_cursor_changed))
    add @treeview
  end

  private

  def create_renderer(col_id)
    renderer = create(CellRendererText,
                      editable: @writer_list[col_id].to_bool)
    renderer.signal_connect 'edited' do |_, path, value|
      iter = @list_store.get_iter(path)
      iter[col_id + 1] = value
      obj = object(iter[FLD_ID].to_i)
      copy_to_obj(iter, obj)
    end
    renderer
  end

  def install_columns(headers)
    nfields = headers.size
    nfields.times do |i|
      renderer = create_renderer(i)
      create(TreeViewColumn, headers[i], renderer, { text: i + 1 },
             resizable: true, clickable: false) do |col|
        col.signal_connect('clicked', &column_click_handler(col, i))
        @treeview.append_column col
      end
    end
  end

  def column_click_handler(col, i)
    proc do
      @treeview.columns.each { |c| c.sort_indicator = false if c != col }
      if !col.sort_indicator? || col.sort_order == DOWN_ARROW
        col.set(sort_indicator: true, sort_order: UP_ARROW)
        @list_store.set_sort_column_id(i + 1, Gtk::SORT_ASCENDING)
      else
        col.set(sort_order: DOWN_ARROW)
        @list_store.set_sort_column_id(i + 1, Gtk::SORT_DESCENDING)
      end
    end
  end

  def on_cursor_changed(*_)
    iter = @treeview.selection.selected
    self.selected = iter ? object(iter[FLD_ID].to_i) : nil
  end

  def object(id)
    fail TypeError, '#{id.inspect} is not an object ID' unless id.is_a? Fixnum
    @objects.find { |obj| obj.object_id == id }
  end

  def selected=(obj)
    @selected = obj
    changed
    notify_observers
  end

  def populate_table
    @list_store.clear
    @objects.each do |obj|
      iter = @list_store.append
      copy_to_iter(obj, iter)
    end
    @treeview.columns.each { |c| c.sort_indicator = false }
  end

  def copy_to_iter(obj, iter)
    values = @reader_list.map { |f| f.call(obj) }
    iter[FLD_ID] = obj.object_id.to_s
    values.each_with_index { |val, i| iter[i + 1] = val }
  end

  def copy_to_obj(iter, obj)
    @writer_list.each_with_index do |writer, i|
      @writer_list[i].call(obj, iter[i+1])
    end
  end

  def select_row(row_number)
    @list_store.to_enum.with_index do |(_model, _path, iter), i|
      if i == row_number
        @treeview.selection.select_iter iter
        break
      end
    end
  end

  public

  def set(ary)
    fail unless ary.is_a? Array

    @objects = ary
    populate_table
    changed
    notify_observers
  end

  def get
    @objects
  end

  def can_go_up?
    selected && @objects.index(selected) != 0
  end

  def go_up
    return unless can_go_up?
    obj = selected
    old_pos = @objects.index(obj)
    @objects.delete(obj)
    @objects.insert(old_pos - 1, obj)
    populate_table
    select_row(old_pos - 1)
    changed
    notify_observers
  end

  def can_go_down?
    selected && @objects.index(selected) != @objects.size - 1
  end

  def go_down
    return unless can_go_down?
    obj = selected
    old_pos = @objects.index(obj)
    @objects.delete(obj)
    @objects.insert(old_pos + 1, obj)
    populate_table
    select_row(old_pos + 1)
    changed
    notify_observers
  end

  def delete
    return unless selected

    @objects.delete(selected)
    populate_table
    changed
    notify_observers
  end

  def can_delete?
    selected ? true : false
  end

  # アイテム追加用サブダイアログ
  class AddItemDialog < Gtk::Dialog
    include Gtk::Stock, GtkHelper, Gtk

    def initialize(parent, headers, constructor)
      super('項目を追加する', parent, MODAL)

      @constructor = constructor
      @entries = []

      do_layout(headers)
    end

    def do_layout(headers)
      headers.each do |text|
        create(Label, text) { |label| vbox.pack_start(label, false) }
        create Entry do |entry|
          @entries << entry
          vbox.pack_start(entry, false)
        end
      end

      vbox.pack_start(HSeparator.new, false)
      add_buttons
    end

    def add_buttons
      add_button(CANCEL, RESPONSE_CANCEL)
      add_button(OK, RESPONSE_OK)

      set_alternative_button_order [RESPONSE_OK, RESPONSE_CANCEL]
    end

    def result
      @constructor.call(*@entries.map(&:text))
    end
  end

  def run_add_dialog(parent = nil)
    fail 'object constructor not set' unless @constructor

    dialog = AddItemDialog.new(parent, @headers, @constructor).show_all
    dialog.run do |response|
      add_object(dialog.result) if response == RESPONSE_OK
      dialog.destroy
    end
  end

  def add_object(result)
    @objects << result
    populate_table
    changed
    notify_observers
  end
end
