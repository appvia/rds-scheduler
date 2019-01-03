#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'rds_scheduler'

def main(*)
  RDSScheduler.new.execute
end
