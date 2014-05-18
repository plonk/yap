class MainWindow < Gtk::Window
  class UIManager < Gtk::UIManager
    def initialize
      super
      add_ui(Resource['ui_definition.xml'])
    end
  end
end
