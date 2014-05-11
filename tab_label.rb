class TabLabel < Gtk::Label
  def initialize page
    @page = page

    super(@page.title)

    @page.add_observer(self)
    
    signal_connect("destroy") do 
      @page.delete_observer(self)
    end
  end

  def update
    Gtk.queue do
      self.text = @page.title
    end
  end
end
