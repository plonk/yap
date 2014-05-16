# -*- coding: utf-8 -*-
require 'rubygems'
require 'webmock'
require 'open-uri'
require_relative '../yellowpage'
require_relative '../channel'
require_relative 'test_data'

index_txt = ORDINARY_CHANNEL_LINE + "\n"
WebMock.stub_request(:get, 'http://naiyo.yoteichi.com/index.txt')
  .to_return(:body => index_txt)

YP_NAME = 'モックYP'
yp = YellowPage.get('モックYP', 'http://naiyo.yoteichi.com/', nil, 'getgmt.php?cn=')
yp.retrieve
ord, uptest = yp.to_a

describe YellowPage do
  it "'s name matches the first arg to new" do
    yp.name.should eq(YP_NAME)
  end

  it 'index.txt の行数と同じ数だけの Channel を含む' do
    yp.to_a.size.should eq(index_txt.split(/\n/).size)
  end

  it 'chat_url_for はチャットURLの設定がなければ空文字列を返す' do
    yp.chat_url_for(ord).should eq('')
  end

  it 'stat_url_for' do
    yoteichi_encoded = '%E4%BA%88%E5%AE%9A%E5%9C%B0'
    yp.stat_url_for(ord).should eq("http://naiyo.yoteichi.com/getgmt.php?cn=#{yoteichi_encoded}")
  end
end
