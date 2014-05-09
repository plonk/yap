require_relative  'config.rb'

class Resource_
  def initialize(directory)
    @directory = directory
  end

  def path(name)
    path = @directory / name
    unless File.exist? path and File.readable? path
      raise Errno::ENOENT, "No file for resource name #{name.inspect}"
    end
    path
  end

  alias :[] :path
end

Resource = Resource_.new($RESOURCE_DIR)
