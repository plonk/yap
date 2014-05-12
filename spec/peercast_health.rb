require_relative '../peercast_health'

describe PeercastHealth do
  context "with localhost" do 
    checker = PeercastHealth.new('localhost', 7144)

    describe 'PeercastHealth#check' do
      it 'returns false' do
        checker.check.should eq(false)
      end
    end

    describe 'PeercastHealth#error_reason' do
      it 'is "connection refused"' do
        checker.error_reason.should eq("connection refused")
      end
    end
  end

  context "with a valid node" do
    checker = PeercastHealth.new('windows', 7144)

    describe 'PeercastHealth#check' do
      it 'returns true' do
        checker.check.should eq(true)
      end
    end

    describe 'PeercastHealth#error_reason' do
      it 'equals nil' do
        checker.error_reason.should eq(nil)
      end
    end
  end

  context "with a host that ignores" do
    checker = PeercastHealth.new('192.168.0.1', 7144, 0.2)

    describe 'PeercastHealth#check' do
      it 'returns false' do
        checker.check.should eq(false)
      end
    end

    describe 'PeercastHealth#error_reason' do
      it 'is "connection timed out"' do
        checker.error_reason.should eq("connection timed out")
      end
    end
  end

  context "with a nonexistent node" do
    checker = PeercastHealth.new('192.168.0.127', 7144, 0.2)

    describe 'PeercastHealth#check' do
      it 'returns false' do
        checker.check.should eq(false)
      end
    end

    describe 'PeercastHealth#error_reason' do
      it 'is "connection timed out"' do
        checker.error_reason.should eq("connection timed out")
      end
    end
  end
end

