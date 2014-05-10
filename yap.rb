#!ruby
# -*- coding: utf-8 -*-
# イエローページビュアーあるいは yap (Yet Another PCYP)
require 'gtk2'
require "resolv"
require "net/http"
require "dbm"

require_relative 'settings'
require_relative "utility"
require_relative "channel"
require_relative "threadhack"
require_relative "yellowpage"
require_relative "extensions"
require_relative 'resource'

#STDOUT.external_encoding("Shift_JIS")
$log = StringIO.new("", "w")
$real_stdout = $stdout.dup
$RUNNING_ON_RUBYW = false
if File.basename(get_exec_filename).downcase == "rubyw.exe"
  $RUNNING_ON_RUBYW = true
end
if $RUNNING_ON_RUBYW
  $stdout = $log
  $stderr = File.new("errlog.txt", "w")
end
Thread.abort_on_exception = true

$ENABLE_VIEWLOG = false

require_relative "web_resource"

QUESTION_16 = Gdk::Pixbuf.new Resource["question16.ico"]
QUESTION_64 = Gdk::Pixbuf.new Resource["question64.ico"]
LOADING_16 = Gdk::Pixbuf.new Resource["loading.ico"]

require_relative "info_dialog"
require_relative "log_dialog"
require_relative "favorite_dialog"
require_relative "settings_dialog"

# ------------------------------------------------------------------

require_relative 'settings'

require_relative "main_window"

window = MainWindow.new
unless defined? Ocra
  window.show_all 
end

begin
  puts "Going into the main loop"
  Gtk.main
rescue Interrupt
  # なんか変だ
  window.finalize
ensure
  if $RUNNING_ON_RUBYW
    File.open("outlog.txt", "w") do |f|
      f.write $log.string
    end
  end
end
