# -*- coding: utf-8 -*-
require_relative 'main_window'

describe MainWindow, 'duration_on_air' do
  it '0 分では空文字列を返す' do
    MainWindow.duration_on_air(0).should eq('')
  end

  it "59 分では'59分経過'を返す" do
    MainWindow.duration_on_air(59).should eq('59分経過')
  end

  it "60分では'1時間0分経過'を返す" do
    MainWindow.duration_on_air(60).should eq('1時間0分経過')
  end
end

