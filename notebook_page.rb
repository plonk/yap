class Page < Gtk::VBox
  include Observable
  attr_reader :title, :label

  def initialize
    super()

    @label = TabLabel.new(self)
  end

  def title=(str)
    @title = str
    changed
    notify_observers
  end
end
