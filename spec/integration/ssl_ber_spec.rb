require 'spec_helper'

require 'net/ldap'
require 'timeout'

describe "BER serialisation (SSL)" do
  # Transmits str to #to and reads it back from #from.
  #
  def transmit(str)
    Timeout::timeout(1) do
      to.write(str)
      to.close

      from.read
    end
  end

  attr_reader :to, :from
  before(:each) do
    @from, @to = IO.pipe

    # The production code operates on sockets, which do need #connect called
    # on them to work. Pipes are more robust for this test, so we'll skip
    # the #connect call since it fails.
    flexmock(OpenSSL::SSL::SSLSocket).
      new_instances.should_receive(:connect => nil)

    @to   = Net::LDAP::Connection.wrap_with_ssl(to)
    @from = Net::LDAP::Connection.wrap_with_ssl(from)
  end

  it "should transmit strings" do
    transmit('foo').should == 'foo'
  end
  it "should correctly transmit numbers" do
    to.write 1234.to_ber
    from.read_ber.should == 1234
  end
end