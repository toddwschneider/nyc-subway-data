require './config/boot'
require './config/environment'

require 'clockwork'
include Clockwork

module Clockwork
  configure do |config|
    config[:tz] = "America/New_York"
  end
end

every(1.minute, 'record observations') do
  RealtimeFeed.record_observations_for_all
end
