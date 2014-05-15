# -*- coding: utf-8 -*-
require 'rubygems'
require 'webmock'
require 'open-uri'
require_relative '../channel'
require_relative '../extensions'

ordinary_channel =
  ['予定地',
   'AE91BBC0A36C2F8C73DA9556860D7890',
   '218.45.166.124:7144',
   'http://jbbs.shitaraba.net/bbs/read.cgi/game/48538/1395690547/',
   'プログラミング',
   'Ruby - &lt;Free&gt;',
   '-1',
   '-1',
   '497',
   'WMV',
   '',
   '',
   '',
   '',
   '%E4%BA%88%E5%AE%9A%E5%9C%B0',
   '0:34',
   'click',
   '',
   '0'].join('<>')
uptest_channel =
  ['アップロード帯域',
   '00000000000000000000000000000000',
   '',
   'http://naiyo.yoteichi.com/uptest/',
   '',
   'No data 帯域測定はコンタクトURL から',
   '-1',
   '-1',
   '',
   'RAW',
   '',
   '',
   '',
   '',
   '',
   '0:00',
   'click',
   '',
   '0'].join('<>')
index_txt = [ordinary_channel, uptest_channel].join("\n") + "\n"
WebMock.stub_request(:get, 'http://naiyo.yoteichi.com/index.txt')
  .to_return(:body => index_txt)

require_relative '../yellowpage'

yp = YellowPage.get('モックYP', 'http://naiyo.yoteichi.com/', nil, nil)
yp.retrieve
ord, uptest = yp.to_a

require_relative '../bandwidth_checker'

describe BandwidthChecker do
  context 'with ordinary channel' do
    describe 'BandwidthChecker.new' do
      it 'raises ArgumentError' do
        proc { BandwidthChecker.new(ord) }
          .should raise_error(ArgumentError, 'not an uptest channel object')
      end
    end
  end

  context 'with uptest channel' do
    describe 'BandwidthChecker.new' do
      it "'s state is 'initialized'" do
        BandwidthChecker.new(uptest).state.should eq('initialized')
      end
    end
  end
end
