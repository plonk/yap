# -*- coding: utf-8 -*-
require 'singleton'
require_relative 'launcher'

# タイプ関連付けをルックアップするためのクラス
class TypeAssociation
  include Singleton

  def initialize
    @identity_map = {}
  end

  def launcher(type)
    Settings[:TYPE_ASSOC].each do |type_pattern, cmdline|
      next unless type =~ /^#{type_pattern}$/i

      @identity_map[cmdline] ||= Launcher.new(cmdline)
      return @identity_map[cmdline]
    end
    nil
  end
end
