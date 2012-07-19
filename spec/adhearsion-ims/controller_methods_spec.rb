require 'spec_helper'

module Adhearsion::IMS
  describe Adhearsion::IMS do
    describe "mixed in to a Adhearsion::IMS" do

      class TestController < Adhearsion::CallController
        include Adhearsion::IMS::CallControllerMethods
      end

      Adhearsion::IMS::Plugin.config[:cscf_address]             = '1.1.1.1'
      Adhearsion::IMS::Plugin.config[:originating_ims_identity] = 'foobar.com'

      P_CHARGING_VECTOR_REGEX = /^icid-value=[({]?(0x)?[0-9a-fA-F]{8}([-,]?(0x)?[0-9a-fA-F]{4}){2}((-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{12})|(,\{0x[0-9a-fA-F]{2}(,0x[0-9a-fA-F]{2}){7}\}))[)}]?;orig-ioi=#{Adhearsion::IMS::Plugin.config[:originating_ims_identity]}/
      CALL_HEADERS            = { :p_asserted_identity => 'foo', 
                                  :p_charging_vector   => 'bar',
                                  :misc_header         => 'bah',
                                  :route               => '1234',
                                  :to                  => 'sip:+14155551212@foo.com',
                                  :from                => 'sip:+16505551212@bar.com' }

      
      let(:mock_call) { mock 'Call' }

      subject do
        mock_call.stubs(:variables).returns(CALL_HEADERS)
        TestController.new mock_call
      end

      describe "#isc_header_copy" do
        describe "when an SBC is not required" do
          it "returns the headers needed to complete an IMS B2BUA call, while stripping ones it does not" do            
            headers = subject.generate_isc_headers :b2bua
            headers[:route].should eql "#{CALL_HEADERS[:route]}"
            headers[:p_asserted_identity].should eql CALL_HEADERS[:p_asserted_identity]
            headers[:p_charging_vector].should eql CALL_HEADERS[:p_charging_vector]
            headers.has_key?(:misc_header).should eql false
          end
        
          it "returns the headers needed to complete an IMS Out of the Blue (OOB) call" do
            headers = subject.generate_isc_headers :out_of_the_blue
            headers[:route].should eql "#{Adhearsion::IMS::Plugin.config[:cscf_address]}"
            headers[:p_charging_vector].match(P_CHARGING_VECTOR_REGEX).to_s.should eql headers[:p_charging_vector]
          end
        end
        
        describe "when an SBC is required" do
          it "returns the headers needed to complete an IMS B2BUA call, while stripping ones it does not" do
            Adhearsion::IMS::Plugin.config[:sbc_address] = '0.0.0.0'
            headers = subject.generate_isc_headers :b2bua
            headers[:route].should eql "#{Adhearsion::IMS::Plugin.config[:sbc_address]}|||#{CALL_HEADERS[:route]}"
            headers[:p_asserted_identity].should eql CALL_HEADERS[:p_asserted_identity]
            headers[:p_charging_vector].should eql CALL_HEADERS[:p_charging_vector]
            headers.has_key?(:misc_header).should eql false
          end
        
          it "returns the headers needed to complete an IMS Out of the Blue (OOB) call" do
            Adhearsion::IMS::Plugin.config[:sbc_address] = '0.0.0.0'
            headers = subject.generate_isc_headers :out_of_the_blue
            headers[:route].should eql "#{Adhearsion::IMS::Plugin.config[:sbc_address]}|||#{Adhearsion::IMS::Plugin.config[:cscf_address]}"
            headers[:p_charging_vector].match(P_CHARGING_VECTOR_REGEX).to_s.should eql headers[:p_charging_vector]
          end
          
          it "returns the headers when there is more than one route provided in the ISC for a B2BUA call" do
            CALL_HEADERS[:route] = "1234|||4567"
            headers = subject.generate_isc_headers :b2bua
            headers[:route].should eql "#{Adhearsion::IMS::Plugin.config[:sbc_address]}|||1234|||4567"
          end
          
          it "but removes appropriate route nodes when specified int he configuration" do
            Adhearsion::IMS::Plugin.config[:exclude_routes] = ['1234']
            headers = subject.generate_isc_headers :b2bua
            headers[:route].should eql "#{Adhearsion::IMS::Plugin.config[:sbc_address]}|||4567"
            Adhearsion::IMS::Plugin.config[:exclude_routes] = []
          end
        end
      end

      describe "#generate_ims_options" do
        describe "when wanting to complete a call via the IMS" do
          it "should raise an error if the wrong type is provided" do
            begin
              subject.generate_ims_options :foobar
            rescue => e
              e.to_s.should eql "Unknown type of foobar, must be :b2bua or :out_of_the_blue"
            end
          end
          
          it "should raise an error if we do a :b2bua call with a :to" do
            begin
              subject.generate_ims_options :b2bua, :to => 'foo'
            rescue => e
              e.to_s.should eql "If requesting a :b2bua you may not specify a :to"
            end
          end
          
          it "should raise an error if we do an :out_of_the_blue call without a :to and :from" do            
            begin
              subject.generate_ims_options :out_of_the_blue
            rescue => e
              e.to_s.should eql "Must provide a :to and :from in options"
            end
            
            begin
              subject.generate_ims_options :out_of_the_blue, :from => 'bar'
            rescue => e
              e.to_s.should eql "Must provide a :to and :from in options"
            end
            
            begin
              subject.generate_ims_options :out_of_the_blue, :to => 'baz'
            rescue => e
              e.to_s.should eql "Must provide a :to and :from in options"
            end
          end
          
          it "create a B2BUA IMS dial string with the appropriate headers and format with existing headers" do
            ims_data = subject.generate_ims_options(:b2bua)
            ims_data[:sip_uri].should eql "#{CALL_HEADERS[:to].gsub('@foo.com','')}@#{Adhearsion::IMS::Plugin.config[:uvp_address]}"
            ims_data[:options][:from].should eql CALL_HEADERS[:from].gsub('sip', 'tel').gsub('@bar.com','')
            ims_data[:options][:headers][:route].should eql "#{Adhearsion::IMS::Plugin.config[:sbc_address]}|||#{CALL_HEADERS[:route]}"
            ims_data[:options][:headers][:p_asserted_identity].should eql CALL_HEADERS[:p_asserted_identity]
            ims_data[:options][:headers][:p_charging_vector].should eql CALL_HEADERS[:p_charging_vector]
          end
          
          it "create a B2BUA IMS dial string with the appropriate headers and format with a new :from" do
            from = '+12125551212'
            ims_data = subject.generate_ims_options(:b2bua, :from => from)
            ims_data[:sip_uri].should eql "#{CALL_HEADERS[:to].gsub('@foo.com','')}@#{Adhearsion::IMS::Plugin.config[:uvp_address]}"
            ims_data[:options][:from].should eql "tel:#{from}"
            ims_data[:options][:headers][:route].should eql "#{Adhearsion::IMS::Plugin.config[:sbc_address]}|||#{CALL_HEADERS[:route]}"
            ims_data[:options][:headers][:p_asserted_identity].should eql CALL_HEADERS[:p_asserted_identity]
            ims_data[:options][:headers][:p_charging_vector].should eql CALL_HEADERS[:p_charging_vector]
          end
          
          it "create an Out of the Blue dial string with the appropriate headers and format" do
            to   = '+14085551212'
            from = '+12125551212'
            ims_data = subject.generate_ims_options(:out_of_the_blue, { :to => to, :from => from })
            ims_data[:sip_uri].should eql "sip:#{to}@#{Adhearsion::IMS::Plugin.config[:uvp_address]}"
            ims_data[:options][:from].should eql "tel:#{from}"
            ims_data[:options][:headers][:route].should eql "#{Adhearsion::IMS::Plugin.config[:sbc_address]}|||#{Adhearsion::IMS::Plugin.config[:cscf_address]}"
            ims_data[:options][:headers][:p_charging_vector].match(P_CHARGING_VECTOR_REGEX).to_s.should eql ims_data[:options][:headers][:p_charging_vector]
          end
        end
      end
    end
  end
end
