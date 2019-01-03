#!/usr/bin/env ruby
require 'bundler'
Bundler.setup

require 'aws-sdk-rds'
require 'logger'

require_relative 'rds_helper'
require_relative 'time_parser'

class RDSScheduler
  include RDSHelper
  include TimeParser

  attr_reader :dry_run,
              :loop_interval,
              :run_once,
              :tag_uptime_schedule

  def initialize()
    @rds_client = Aws::RDS::Client.new()
    @logger = Logger.new(STDOUT)
    $stdout.sync = true

    @dry_run = ENV.fetch('DRY_RUN', false).to_s.downcase == "true"
    @loop_interval = ENV.fetch('LOOP_INTERVAL', 30).to_i
    @run_once = ENV.fetch('RUN_ONCE', false).to_s.downcase == "true"
    @tag_uptime_schedule = "appvia.io/rds-scheduler/uptime-schedule"
  end


  def execute()
    loop do
      @logger.info "Retrieving DB instances..."
      db_instances = get_db_instances()

      db_instances.each do |rds|
        db_name = rds.db_instance_identifier
        db_status = rds.db_instance_status
        tags = get_db_tags(rds.db_instance_arn)

        db_schedule = false
        tags.each do |tag|
          if tag.key.eql?(tag_uptime_schedule)
            db_schedule = tag.value and break
          end
        end

        unless db_schedule
          @logger.info "DB Instance '#{db_name}' has no schedule defined (status: #{db_status})"
        else
          begin
            parse_schedule(db_schedule)
          rescue => e
            @logger.warn "DB Instance '#{db_name}' has an invalid schedule: #{e.message}"
          else
            if schedule_matches?(db_schedule)
              start_db_instance(db_name, db_status, db_schedule)
            else
              stop_db_instance(db_name, db_status, db_schedule)
            end
          end
        end
      end

      break if run_once
      @logger.info("Sleeping for #{loop_interval} seconds...")
      sleep(loop_interval)
    end
  end

end
