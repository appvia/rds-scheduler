require 'aws-sdk-rds'

module RDSHelper

  def get_db_instances()
    return @rds_client.describe_db_instances.db_instances
  end

  def get_db_tags(db_arn)
    return @rds_client.list_tags_for_resource({
      resource_name: db_arn
    }).tag_list
  end

  def start_db_instance(db_name, db_status, db_schedule)
    unless db_status.eql? "stopped"
      if db_status.eql? "available"
        @logger.info "DB Instance '#{db_name}' is currently available (schedule: #{db_schedule})"
      else
        @logger.warn "DB Instance '#{db_name}' is not in a stopped state, not taking action (status: #{db_status}, schedule: #{db_schedule})"
      end
    else
      @logger.info "Starting DB Instance '#{db_name}' (schedule: #{db_schedule}, dry_run: #{dry_run})"
      @rds_client.start_db_instance({db_instance_identifier: db_name}) unless dry_run
    end
  end

  def stop_db_instance(db_name, db_status, db_schedule)
    if ["stopping", "stopped"].include?(db_status)
      @logger.warn "DB Instance '#{db_name}' is already in a stopped state, not taking action (status: #{db_status}, schedule: #{db_schedule})"
    else
      @logger.info "Stopping DB Instance '#{db_name}' (schedule: #{db_schedule}, dry_run: #{dry_run})"
      @rds_client.stop_db_instance({db_instance_identifier: db_name}) unless dry_run
    end
  end

end
