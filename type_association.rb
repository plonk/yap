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
      if type =~ /^#{type_pattern}$/i
        unless @identity_map.key? cmdline
          @identity_map[cmdline] = Launcher.new(cmdline)
        end
        return @identity_map[cmdline]
      end
    end
    nil
  end
end
