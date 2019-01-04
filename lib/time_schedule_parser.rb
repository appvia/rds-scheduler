# frozen_string_literal: true

require 'active_support/core_ext/numeric/time'
require 'tzinfo'

# Parse time definition strings for validity
class TimeScheduleParser
  WEEKDAYS = %w[MON TUE WED THU FRI SAT SUN].freeze
  TimeSchedule = Struct.new(:day_from, :day_to, :hour_from, :minute_from, :hour_to, :minute_to, :timezone)

  def time_schedule(opts)
    TimeSchedule.new(opts[:day_from], opts[:day_to], opts[:hour_from], opts[:minute_from], opts[:hour_to], opts[:minute_to], opts[:timezone])
  end

  def parse_schedule(schedule)
    # Example: "Mon-Fri 09:00-17:30 Europe/London"
    regexp = %r{^([a-zA-Z]{3})-([a-zA-Z]{3}) (\d\d):(\d\d)-(\d\d):(\d\d) ([a-zA-Z/_]+)$}
    matches = schedule.match(regexp)

    raise 'Schedule does not match regex' if matches.nil?
    raise TimeScheduleParser::TimezoneInvalid, "Timezone is invalid: '#{matches.captures[6]}'" unless TZInfo::Timezone.all_identifiers.include?(matches.captures[6])

    day_from = matches.captures[0].upcase
    day_to = matches.captures[1].upcase
    raise "Day Range is invalid: '#{day_from}-#{day_to}'" unless ([day_from, day_to] - WEEKDAYS).empty?

    time_schedule(
      day_from: day_from,
      day_to: day_to,
      hour_from: matches.captures[2].to_i,
      minute_from: matches.captures[3].to_i,
      hour_to: matches.captures[4].to_i,
      minute_to: matches.captures[5].to_i,
      timezone: matches.captures[6]
    )
  end

  def schedule_active?(schedule)
    begin
      current_time = Time.now.in_time_zone(schedule[:timezone])
    rescue StandardError
      raise TimeScheduleParser::TimezoneInvalid, "Current time could not be computed with the given timezone: '#{schedule[:timezone]}'"
    end

    day_matches = WEEKDAYS.index(current_time.strftime('%a').upcase).between?(WEEKDAYS.index(schedule[:day_from]), WEEKDAYS.index(schedule[:day_to]))
    current_minutes = (current_time.hour * 60) + current_time.min
    time_matches = current_minutes.between?((schedule[:hour_from] * 60) + schedule[:minute_from], (schedule[:hour_to] * 60) + schedule[:minute_to])
    day_matches && time_matches
  end

  class TimezoneInvalid < StandardError; end
end
