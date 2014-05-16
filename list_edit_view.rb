# -*- coding: utf-8 -*-
require 'observer'

# ListEditDialog で使う TreeView
class ListEditView < Gtk::TreeView
  include Gtk
  include GtkHelper
  include Observable

  def initialize(parent_window, options)
    @parent_window = parent_window
    check_options(options)

    @movable_rows = options[:movable_rows].to_bool
    @allow_add = options[:allow_add].to_bool
    @allow_delete = options[:allow_delete].to_bool
    @types = options[:types]
    @headers = options[:headers]
    @editable = options[:editable]
    @numfields = @types.size

    @list_store = ListStore.new(*to_ruby_types(@types))
    super(@list_store)

    do_layout

    load_table options[:table]
  end

  def do_layout
    install_columns
    install_menu

    selection.signal_connect('changed') do
      changed
      notify_observers
    end
  end

  def load_table(table)
    @list_store.clear
    table.each do |row|
      add_row(row)
    end
  end

  def result
    @list_store.to_enum.map do |_liststore, _path, iter|
      @numfields.times.map { |i| iter[i] }
    end
  end

  def add_menu_item_activated(_add_item)
    run_add_item_dialog
  end

  def delete_menu_item_activated(_del_item)
    delete
  end

  def add_row(row)
    iter = @list_store.append
    @numfields.times do |i|
      iter[i] = row[i]
    end
  end

  def create_context_menu
    create(Menu) do |menu|
      create(MenuItem, '追加',
             on_activate: method(:add_menu_item_activated)) do |add_item|
        menu.append add_item
      end
      create(MenuItem, '削除',
             on_activate: method(:delete_menu_item_activated)) do |del_item|
        menu.append del_item
      end
    end
  end

  def install_columns
    @types.each_with_index do |type, i|
      renderer = create_renderer(type, @editable[i], i)
      col = TreeViewColumn.new(@headers[i], renderer,
                               model_property(type) => i)
      append_column col
    end
  end

  def install_menu
    menu = create_context_menu.show_all
    set(events: Gdk::Event::BUTTON_PRESS_MASK,
        on_button_press_event: proc do |_button, e|
          if e.button == 3
            menu.popup(nil, nil, e.button, e.time)
            true
          else
            false
          end
        end)
  end

  def model_property(type)
    case type
    when :text then :text
    when :toggle then :active
    when :radio then :active
    else
      fail "unknown type #{type}"
    end
  end

  def options_consistent?(options)
    sizes = [:types, :editable, :headers].map(&options.method(:[])).map(&:size)
    sizes.all?(&sizes[0].method(:==))
  end

  def to_ruby_types(column_types)
    column_types.map do |col|
      case col
      when :text then String
      when :toggle then ::Object
      when :radio then ::Object
      else
        fail "unknown type #{col}"
      end
    end
  end

  def check_options(options)
    fail ArgumentError, 'lack of mandatory options' if
      [:types, :editable, :table, :headers]
      .map(&options.method(:[]))
      .any?(&:nil?)
    fail ArgumentError unless options_consistent?(options)
  end

  def create_toggle_renderer(editable, col_id)
    create(CellRendererToggle) do |cr|
      cr.signal_connect 'toggled' do |_renderer, path|
        iter = @list_store.get_iter path
        iter[col_id] = !iter[col_id]
      end if editable
    end
  end

  def create_radio_renderer(editable, col_id)
    create(CellRendererToggle, radio: true) do |cr|
      cr.signal_connect 'toggled' do |_renderer, path|
        @list_store.each do |_model, _path, iter|
          iter[col_id] = false
        end
        iter = @list_store.get_iter path
        iter[col_id] = true
      end if editable
    end
  end

  def create_text_renderer(editable, col_id)
    create(CellRendererText, editable: editable) do |cr|
      cr.signal_connect 'edited' do |_renderer, path, value|
        @list_store.get_iter(path)[col_id] = value
      end if editable
    end
  end

  def create_renderer(type, editable, col_id)
    case type
    when :toggle then create_toggle_renderer(editable, col_id)
    when :radio  then create_radio_renderer(editable, col_id)
    when :text   then create_text_renderer(editable, col_id)
    else fail "unknown type #{type}"
    end
  end

  # 以下 ObjectListControlBox とお話するためのインターフェイス

  def run_add_dialog(parent_window = @parent_window)
    return unless @allow_add

    dialog = AddItemDialog.new(parent_window, @headers, @types).show_all
    dialog.run do |response|
      case response
      when RESPONSE_OK
        add_row(dialog.result)
      when RESPONSE_CANCEL, RESPONSE_DELETE_EVENT
      else fail
      end
    end
    dialog.destroy
  end

  def delete
    @list_store.remove selection.selected if !@allow_delete && selection.selected
  end

  def go_up
    return unless can_go_up?

    old_row = selection.selected
    prev_path = old_row.path
    prev_path.prev!
    prev_row = @list_store.get_iter prev_path
    @list_store.move_before(old_row, prev_row)
    # この操作では selection の changed シグナルが発行されないようなので
    # 自力で通知する
    changed
    notify_observers
  end

  def go_down
    return unless can_go_down?

    old_row = selection.selected
    next_row = old_row.dup
    next_row.next!
    @list_store.move_after(old_row, next_row)
    changed
    notify_observers
  end

  def can_add?
    @allow_add
  end

  def can_go_up?
    @movable_rows && selection.selected && selection.selected.path.to_s != '0'
  end

  def can_go_down?
    @movable_rows && selection.selected && selection.selected.dup.next! != false
  end

  def can_delete?
    @allow_delete && selection.selected.to_bool
  end

  # アイテム追加ダイアログ
  class AddItemDialog < Gtk::Dialog
    include Gtk
    include GtkHelper

    attr_reader :result

    def value(widget)
      case widget
      when ToggleButton
        widget.active?
      when Entry
        widget.text
      else fail 'missing case'
      end
    end

    def initialize(parent_window, headers, types)
      super('アイテムを追加', parent_window)

      @headers = headers
      @types = types
      @views = []

      do_layout

      @ok_button.signal_connect 'clicked' do
        @result = @views.map(&method(:value))
      end
    end

    def create_field_widget(type)
      case type
      when :text
        create(Entry, width_request: 150)
      when :toggle
        create(CheckButton)
      when :radio
        create(CheckButton, active: false, sensitive: false)
      else fail "unknown widget type (#{type})"
      end
    end

    def do_layout
      vbox.set(spacing: 5)
      vbox.pack_start(create_table, false)
      add_buttons
    end

    def create_table
      create(Table, 2, @headers.size,
             row_spacings: 5, column_spacings: 10) do |table|
        @headers.each_with_index do |header, col_id|
          table.attach_defaults(create(Label, header, xalign: 1),
                                0, 1, col_id, col_id + 1)

          widget = create_field_widget @types[col_id]
          @views << widget
          table.attach_defaults(widget, 1, 2, col_id, col_id + 1)
        end
      end
    end

    def add_buttons
      add_button Stock::CANCEL, RESPONSE_CANCEL
      @ok_button = add_button Stock::OK, RESPONSE_OK

      set_alternative_button_order [RESPONSE_OK, RESPONSE_CANCEL]
    end
  end
end
