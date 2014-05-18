#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# イエローページビュアーあるいは yap (Yet Another PCYP)
require_relative 'ui'

$stdout = StringIO.new('', 'w') if ::Settings[:ENABLE_VIEWLOG]
Thread.abort_on_exception = true

UI.new(MainWindowModel.new).run
