#!/usr/bin/env ruby
require_relative 'rds_scheduler'

def main(event:, context:)
  RDSScheduler.new().execute
end
