# -*- coding: utf-8 -*-
class YapAboutDialog < Gtk::AboutDialog
  include Gtk
  include GtkHelper

  def initialize
    super()

    comments = ["GTK+ #{Gtk::VERSION.join('.')}",
                "Ruby/GTK #{Gtk::BINDING_VERSION.join('.')}" +
                "(built for #{Gtk::BUILD_VERSION.join('.')})",
                "Ruby #{RUBY_VERSION} [#{RUBY_PLATFORM}]",
                "Nokogiri #{Nokogiri::VERSION}",
                "Mechanize #{Mechanize::VERSION}"].join("\n")

    set(program_name: "YAP",
        version: "0.0.3",
        comments: comments,
        authors: ['予定地'],
        website: 'https://github.com/plonk/yap') 

    signal_connect('response') do
      destroy
    end
  end
end
