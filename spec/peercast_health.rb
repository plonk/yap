require_relative 'peercast_health'

describe PeercastHealth do
  it "localhost" do 
    checker = PeercastHealth.new('localhost', 7144)
    checker.check.should eq(false)
    checker.error_reason.should eq("connection refused")
  end

  it "valid node" do
    checker = PeercastHealth.new('windows', 7144)
    checker.check.should eq(true)
    checker.error_reason.should eq(nil)
  end

  it "host that ignores" do
    checker = PeercastHealth.new('192.168.0.1', 7144, 0.2)
    checker.check.should eq(false)
    checker.error_reason.should eq("connection timed out")
  end

  it "nonexistent node" do
    checker = PeercastHealth.new('192.168.0.127', 7144, 0.2)
    checker.check.should eq(false)
    checker.error_reason.should eq("connection timed out")
  end
end

