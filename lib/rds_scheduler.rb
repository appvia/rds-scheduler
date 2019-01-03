# frozen_string_literal: true

require 'bundler'
Bundler.setup
require 'aws-sdk-rds'
require 'logger'
require_relative 'rds_helper'
require_relative 'time_schedule_parser'

# Manage uptime schedules for RDS Instances
class RDSScheduler
  def initialize
    @logger = Logger.new(STDOUT)
    $stdout.sync = true
    dry_run = ENV.fetch('DRY_RUN', false).to_s.casecmp('true').zero?
    @loop_interval = ENV.fetch('LOOP_INTERVAL_SECS', 60).to_i
    @rds_client = RDSHelper.new(dry_run: dry_run, logger: @logger)
    @run_once = ENV.fetch('RUN_ONCE', false).to_s.casecmp('true').zero?
    @tag_uptime_schedule = ENV.fetch('TAG_UPTIME_SCHEDULE', 'appvia.io/rds-scheduler/uptime-schedule')
    @time_parser = TimeScheduleParser.new
  end

  def execute
    loop do
      @logger.info 'Retrieving DB instances...'
      dbs = @rds_client.db_instances

      dbs.each do |rds|
        tags = @rds_client.db_tags(rds.db_instance_arn)

        db_schedule = false
        tags.each do |tag|
          (db_schedule = tag.value) && break if tag.key.eql?(@tag_uptime_schedule)
        end

        process_schedule(rds.db_instance_identifier, rds.db_instance_status, db_schedule)
      end

      break if @run_once

      @logger.info("Sleeping for #{@loop_interval} seconds...")
      sleep(@loop_interval)
    end
  end

  def process_schedule(db_name, db_status, db_schedule)
    if db_schedule
      begin
        parsed_schedule = @time_parser.parse_schedule(db_schedule)
      rescue StandardError => e
        @logger.warn "DB Instance '#{db_name}' has an invalid schedule: #{e.message}"
      else
        begin
          if @time_parser.schedule_active?(parsed_schedule)
            @rds_client.start_db_instance(db_name, db_status, db_schedule)
          else
            @rds_client.stop_db_instance(db_name, db_status, db_schedule)
          end
        rescue TimeScheduleParser::TimezoneInvalid => e
          @logger.error "Error processing Time Schedule for DB Instance '#{db_name}': #{e.message}"
        end
      end
    else
      @logger.info "DB Instance '#{db_name}' has no schedule defined (status: #{db_status})"
    end
  end
end
