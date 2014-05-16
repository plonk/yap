# -*- coding: utf-8 -*-
require_relative 'gtk_helper'

module GtkHelper
  def create(klass, *args, &block)
    if args.last.is_a? Hash
      options = args.pop
    else
      options = {}
    end
    widget = klass.new(*args)

    widget.__set__(options)

    block.call(widget) if block

    widget
  end

  def head(str, tooltip = nil)
    label = Gtk::Label.new(str + ':')
    label.xalign = 1
    label.yalign = 0.5
    label.tooltip_text = tooltip if tooltip
    label
  end

  def cell(str)
    label = Gtk::Label.new(str)
    label.selectable = true
    label.yalign = 0.5
    label.xalign = 0
    label
  end
end

# 開いてモンキーパッチ
class GLib::Object
  def set(options)
    callbacks, normal = options.keys.partition { |sym| sym =~ /^on_/ }

    # オプション引数の処理
    callbacks.each do |name|
      callback = options[name]
      signal = name.to_s.sub(/\Aon_/, '')
      signal_connect(signal, &callback)
    end

    normal.each do |name|
      value = options[name]
      send(name.to_s + '=', value)
    end

    self
  end

  alias_method :__set__, :set
end
