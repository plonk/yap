# -*- coding: utf-8 -*-
require 'observer'

class ObjectList < Gtk::ScrolledWindow
  include Gtk, GtkHelper, Observable

  attr_reader :treeview
  attr_reader :selected

  # 上矢印が昇順がいい。
  UP_ARROW = Gtk::SORT_DESCENDING
  DOWN_ARROW = Gtk::SORT_ASCENDING

  def initialize headers, reader_list, writer_list
    super()

    self.hscrollbar_policy = POLICY_AUTOMATIC

    @objects = []
    @reader_list = reader_list.map(&:to_proc)
    @writer_list = writer_list.map { |writer|
      if writer then writer.to_proc else nil end
    }
    types = [String] * @reader_list.size
    @list_store = ListStore.new(*[String] + types)
    @treeview = create(TreeView, @list_store)

    install_columns(headers)
    @treeview.search_column = 1

    @treeview.selection.signal_connect('changed', &method(:on_cursor_changed))
    add @treeview
  end

  private
  def get_object(iter)
    @objects.select { |obj| obj.object_id.to_s == iter[0] }.first
  end
  
  def create_renderer col_id
    renderer = create(CellRendererText, editable: @writer_list[col_id] != nil)
    renderer.signal_connect 'edited' do |_, path, value|
      iter = @list_store.get_iter(path)
      obj = get_object(iter) 
      iter[col_id+1] = value
      @writer_list[col_id].call(obj, value)
    end
    renderer
  end

  def install_columns headers
    nfields = headers.size
    nfields.times do |i|
      renderer = create_renderer(i)
      create(TreeViewColumn, headers[i],
             renderer,
             {text: i+1},
             resizable: true, clickable: true) do |col|
        col.signal_connect('clicked') do
          @treeview.columns.each do |c|
            if c!=col
              c.sort_indicator = false
            end
          end

          if !col.sort_indicator? or col.sort_order==DOWN_ARROW
            col.sort_indicator = true
            col.sort_order = UP_ARROW
            @list_store.set_sort_column_id(i+1, Gtk::SORT_ASCENDING)
          else
            col.sort_order = DOWN_ARROW
            @list_store.set_sort_column_id(i+1, Gtk::SORT_DESCENDING)
          end
        end
        @treeview.append_column col
      end
    end
  end

  def on_cursor_changed *_
    if iter = @treeview.selection.selected
      object_id = iter[0]
      obj = @objects.select { |obj| obj.object_id.to_s == object_id }.first
      @selected = obj
    else
      @selected = nil
    end
    changed
    notify_observers
  end

  def populate_table
    @list_store.clear
    @objects.each do |obj|
      iter = @list_store.append
      values = @reader_list.map { |f| f.call(obj) }
      iter[0] = obj.object_id.to_s
      values.each_with_index { |val, i| iter[i+1] = val }
    end
    @treeview.columns.each {|c| c.sort_indicator = false }
  end

  def select_row index
    i = 0
    @list_store.each do |model, path, iter|
      if i==index
        @treeview.selection.select_iter iter
        break
      end
      i += 1
    end
  end

  public
  def set ary
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
    if selected == nil
      false
    elsif @objects.index(selected) != 0
      true
    else
      false
    end
  end

  def go_up
    return unless can_go_up?
    obj = selected
    old_pos = @objects.index(obj)
    @objects.delete(obj)
    @objects.insert(old_pos - 1, obj)
    populate_table
    select_row(old_pos-1)
    changed
    notify_observers
  end

  def can_go_down?
    if selected == nil
      false
    elsif @objects.index(selected) != @objects.size - 1
      true
    else
      false
    end
  end

  def go_down
    return unless can_go_down?
    obj = selected
    old_pos = @objects.index(obj)
    @objects.delete(obj)
    @objects.insert(old_pos + 1, obj)
    populate_table
    select_row(old_pos+1)
    changed
    notify_observers
  end

  def delete
    if selected
      @objects.delete(selected)
      populate_table
      changed
      notify_observers
    end
  end
end
