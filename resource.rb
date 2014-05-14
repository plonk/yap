require_relative 'config.rb'

class Resource_
  def initialize(directory)
    @directory = directory
  end

  def path(name)
    path = @directory / name
    unless File.exist? path and File.readable? path
      fail Errno::ENOENT, "No file for resource name #{name.inspect}"
    end
    path
  end

  alias_method :[], :path
end

Resource = Resource_.new($RESOURCE_DIR)
