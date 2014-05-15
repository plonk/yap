# -*- coding: utf-8 -*-
require 'rubygems'
require 'webmock'
require 'open-uri'
require_relative '../channel'
require_relative '../extensions'
require_relative 'test_data'

ordinary_channel = ORDINARY_CHANNEL_LINE
uptest_channel = UPTEST_CHANNEL_LINE
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
