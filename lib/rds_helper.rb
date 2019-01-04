# frozen_string_literal: true

require 'aws-sdk-rds'

# Make calls to the AWS RDS API
class RDSHelper
  def initialize(dry_run: false, logger: nil)
    @rds_client = Aws::RDS::Client.new
    @logger = logger
    @dry_run = dry_run
  end

  def db_instances
    @rds_client.describe_db_instances.db_instances
  end

  def db_tags(db_arn)
    @rds_client.list_tags_for_resource(
      resource_name: db_arn
    ).tag_list
  end

  def start_db_instance(db_name, db_status, db_schedule)
    if db_status.eql? 'stopped'
      @logger.info "Starting DB Instance '#{db_name}' (schedule: '#{db_schedule}', dry_run: #{@dry_run})"
      @rds_client.start_db_instance(db_instance_identifier: db_name) unless @dry_run
    elsif db_status.eql? 'available'
      @logger.info "DB Instance '#{db_name}' is currently available (schedule: '#{db_schedule}')"
    else
      @logger.warn "DB Instance '#{db_name}' is not in a stopped state, not taking action (status: #{db_status}, schedule: '#{db_schedule}')"
    end
  end

  def stop_db_instance(db_name, db_status, db_schedule)
    if %w[stopping stopped].include?(db_status)
      @logger.info "DB Instance '#{db_name}' is currently stopped (status: #{db_status}, schedule: '#{db_schedule}')"
    elsif db_status.eql? 'available'
      @logger.info "Stopping DB Instance '#{db_name}' (schedule: '#{db_schedule}', dry_run: #{@dry_run})"
      @rds_client.stop_db_instance(db_instance_identifier: db_name) unless @dry_run
    else
      @logger.warn "DB Instance '#{db_name}' is not in a running state, not taking action (status: #{db_status}, schedule: '#{db_schedule}')"
    end
  end
end
