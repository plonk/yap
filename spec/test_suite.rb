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

require_relative 'yellowpage'
require_relative 'channel'

sp = YellowPage.new('SP', 'http://bayonet.ddo.jp/sp/', nil)
testline = '予定地<>AE91BBC0A36C2F8C73DA9556860D7890<>218.45.166.124:7144<>http://jbbs.shitaraba.net/bbs/read.cgi/game/48538/1395690547/<>プログラミング<>Ruby - &lt;Free&gt;<>-1<>-1<>497<>WMV<><><><><>%E4%BA%88%E5%AE%9A%E5%9C%B0<>0:34<>click<><>0'
describe YellowPage, '' do
  it "'s name matches the first arg to new" do
    sp.name.should eq('SP')
  end

  it 'chat_url_for はチャットURLの設定がなければ空文字列を返す' do
    ch = Channel.new(testline)
    sp.chat_url_for(ch).should eq('')
  end

  it 'stat_url_for' do
    ch = Channel.new(testline)
    sp.stat_url_for(ch).should eq('http://bayonet.ddo.jp/sp/getgmt.php?cn=%E4%BA%88%E5%AE%9A%E5%9C%B0')
  end
end
