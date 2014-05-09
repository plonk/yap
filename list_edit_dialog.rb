# -*- coding: utf-8 -*-
require 'gtk2'
require_relative 'gtk_helper'

class ListEditDialog < Gtk::Dialog
  class AddItemDialog < Gtk::Dialog
    include Gtk
    include GtkHelper

    attr_reader :result

    def value widget
      case widget
      when ToggleButton
        widget.active?
      when Entry
        widget.text
      end
    end

    def initialize parent_window, headers, types
      super('アイテムを追加', parent_window)

      # self.width_request = 320
      @views = []

      vbox.spacing = 5
      headers.each_with_index do |header, col_id|
        vbox.add create(HBox) { |hbox|
          create(Label, header) do |legend|
            legend.width_request = 50
            hbox.pack_start legend, false
          end

          case types[col_id]
          when :text
            create(Entry) do |entry|
              entry.width_request = 150
              @views << entry
              hbox.add entry
            end
          when :toggle
            create(CheckButton) do |toggle|
              @views << toggle
              hbox.add toggle
            end
          when :radio
            create(CheckButton) do |toggle|
              toggle.active = false
              toggle.sensitive = false
              @views << toggle
              hbox.add toggle
            end
          else fail
          end
        }
      end

      @ok_button = add_button Stock::OK, RESPONSE_OK
      add_button Stock::CANCEL, RESPONSE_CANCEL

      @ok_button.signal_connect 'clicked' do |button|
        @result = @views.map(&method(:value))
      end
    end
  end

  include Gtk
  include GtkHelper

  def create_renderer(type, editable, col_id)
    case type
    when :toggle
      result = CellRendererToggle.new
      if editable 
        result.signal_connect 'toggled' do |renderer, path|
          iter = @liststore.get_iter path
          iter[col_id] = !iter[col_id]
        end
      end
    when :radio
      result = CellRendererToggle.new
      result.radio = true
      if editable 
        result.signal_connect 'toggled' do |renderer, path|
          @liststore.each do |model, path, iter|
            iter[col_id] = false
          end
          iter = @liststore.get_iter path
          iter[col_id] = true
        end
      end
    when :text
      result = CellRendererText.new
      result.editable = editable
      result.signal_connect 'edited' do |renderer, path, value|
        @liststore.get_iter(path)[col_id] = value
      end
    else
      fail "unknown type #{type}"
    end
    result
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

  def model_property(type)
    case type
    when :text then :text
    when :toggle then :active
    when :radio then :active
    else
      fail "unknown type #{type}"
    end
  end

  def do_layout
    create(VBox) do |vbox|
      vbox.add(@scrolled_window = create(ScrolledWindow) { |sw|
                 @liststore = ListStore.new(*to_ruby_types(@types))
                 @treeview = TreeView.new(@liststore)
                 sw.add @treeview
               })
      @scrolled_window.set_policy(POLICY_AUTOMATIC, POLICY_AUTOMATIC)
      self.vbox.add vbox
    end

    @ok_button = add_button(Stock::OK, RESPONSE_OK)
  end

  def create_context_menu
    self.width_request = 320
    self.height_request = 200

    create(Menu) do |menu|
      create(MenuItem, "追加") do |add_item|
        add_item.signal_connect('activate') do |item|
          dialog = AddItemDialog.new(self, @headers, @types).show_all
          dialog.run do |response|
            p dialog.result
            p response
            case response
            when RESPONSE_OK
              iter = @liststore.append
              @numfields.times.each do |i|
                iter[i] = dialog.result[i]
              end
            when RESPONSE_CANCEL, RESPONSE_DELETE_EVENT
            else fail
            end
          end
          dialog.destroy
        end

        menu.append add_item
      end
      create(MenuItem, "削除") do |del_item|
        del_item.signal_connect('activate') do |item|
          iter = @treeview.selection.selected
          if iter
            @liststore.remove iter
          end
        end
          
        menu.append del_item
      end
      menu
    end
  end

  def result
    @liststore.to_enum.map do |liststore, path, iter|
      @numfields.times.map { |i| iter[i] }
    end
  end

  def initialize parent_window, options
    super('List Edit Dialog', parent_window)

    optary = [:types, :editable, :table, :headers].map(&options.method(:[]))
    @types, editable, table, @headers = optary

    @numfields = @types.size

    if optary.any?(&:nil?)
      raise ArgumentError, 'lack of mandatory options'
    end
    raise ArgumentError unless options_consistent?(options)

    do_layout

    @menu = create_context_menu.show_all

    @treeview.events = Gdk::Event::BUTTON_PRESS_MASK
    @treeview.signal_connect('button-press-event') do |button, e|
      if e.button == 3
        @menu.popup(nil, nil, e.button, e.time)
        true
      else
        false
      end
    end

    @types.each_with_index do |type, i|
      renderer = create_renderer(type, editable[i], i)
      col = TreeViewColumn.new(@headers[i], renderer, { model_property(type) => i })
      @treeview.append_column col
    end

    table.each do |row|
      iter = @treeview.model.append
      @numfields.times do |i|
        iter[i] = row[i]
      end
    end
  end
end