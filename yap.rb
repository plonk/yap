#!/usr/bin/env ruby
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
require_relative 'web_resource'

$stdout = StringIO.new('', 'w') if ::Settings[:ENABLE_VIEWLOG]
Thread.abort_on_exception = true

UI.new(MainWindowModel.new).run
