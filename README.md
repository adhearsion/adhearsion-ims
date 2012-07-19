adhearsion-ims
==============

A gem that provides convenience methods for integration with the IP Multimedia Subsystem (IMS) when using PRISM and Rayo. This gem is an Adhearsion plugin.

Usage
=====

	class MyCallController < Adhearsion::CallController
	  include Adhearsion::IMS::CallControllerMethods
	
	  def run
	    # Complete the call as a B2BUA, must pass options returned
	    ims_data = ims_dial_string :b2bua
	    dial ims_data[:sip_uri], ims_data[:options]
	    
	    # Complete the call as an Out of the Blue (OOB)
	    ims_data = ims_dial_string :out_of_the_blue
	    dial ims_data[:sip_uri], ims_data[:options]
	  end
	end

Installation
============

	gem install adhearsion-ims

Configuration
=============

The configuration for this plugin should be included in the Adhearsion project within the file config/adhearsion.rb. The options available are:

	config.adhearsion_ims.sbc_address              = "192.168.0.1" #The Hostname or IP Address of the Session Border Gateway (SBG) of the IMS [OPTIONAL]
	config.adhearsion_ims.cscf_address             = "192.168.0.2" #The Hostname or IP Address of the Call Session Control Function (CSCF) of the IMS, can not be nil
	config.adhearsion_ims.originating_ims_identity = 'foobar.com'  #Originating IMS Identity for an Out of the Blue session, can not be nil
	config.adhearsion_ims.uvp_address              = '192.168.0.3' #The Hostname or IP Address of the Universal Voice Platform (UVP) of the IMS
	config.adhearsion_ims.exclude_routes           = ['foo'] #An array of routes to exclude from the route header

