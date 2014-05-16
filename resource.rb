# -*- coding: utf-8 -*-
require_relative 'config.rb'

# インストールディレクトリのファイルを参照するためのクラス
class ResourceClass
  def initialize(directory)
    @directory = directory
  end

  def path(name)
    path = @directory / name
    unless File.exist?(path) && File.readable?(path)
      fail Errno::ENOENT, "No file for resource name #{name.inspect}"
    end
    path
  end

  alias_method :[], :path
end

Resource = ResourceClass.new($RESOURCE_DIR)
