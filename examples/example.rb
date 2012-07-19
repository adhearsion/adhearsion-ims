class MyCallController < Adhearsion::CallController
	include Adhearsion::IMS::CallControllerMethods

	def run
		# Complete the call as a B2BUA
		ims_data = ims_dial_string :b2bua
		dial ims_data[:sip_uri], ims_data[:options]
		
		# Complete the call as an Out of the Blue (OOB)
		ims_data = ims_dial_string :out_of_the_blue
		dial ims_data[:sip_uri], ims_data[:options]
	end
end