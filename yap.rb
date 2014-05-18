#!ruby
# -*- coding: utf-8 -*-
# イエローページビュアーあるいは yap (Yet Another PCYP)
require 'gtk2'
require 'resolv'
require 'net/http'
require 'dbm'

require_relative 'settings'
require_relative 'utility'
require_relative 'channel'
require_relative 'threadhack'
require_relative 'yellowpage'
require_relative 'extensions'
require_relative 'resource'
require_relative 'ui'

# STDOUT.external_encoding("Shift_JIS")
$log = StringIO.new('', 'w')
$real_stdout = $stdout.dup
$RUNNING_ON_RUBYW = false
if File.basename(exec_filename).downcase == 'rubyw.exe'
  $RUNNING_ON_RUBYW = true
end
if $RUNNING_ON_RUBYW
  $stdout = $log
  $stderr = File.new('errlog.txt', 'w')
end
Thread.abort_on_exception = true

$ENABLE_VIEWLOG = false

require_relative 'web_resource'

QUESTION_16 = Gdk::Pixbuf.new Resource['question16.ico']
QUESTION_64 = Gdk::Pixbuf.new Resource['question64.ico']
LOADING_16 = Gdk::Pixbuf.new Resource['loading.ico']

UI.new(MainWindowModel.new).run
