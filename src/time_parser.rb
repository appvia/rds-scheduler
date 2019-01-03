require 'active_support/core_ext/numeric/time'
require 'tzinfo'

WEEKDAYS = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']

module TimeParser

  def parse_schedule(schedule)
    # Example: "Mon-Fri 09:00-17:30 Europe/London"
    regexp = /^([a-zA-Z]{3})-([a-zA-Z]{3}) (\d\d):(\d\d)-(\d\d):(\d\d) ([a-zA-Z\/_]+)$/
    matches = schedule.match(regexp)

    if matches.nil?
      raise "Schedule does not match regex"
    end

    unless TZInfo::Timezone.all_identifiers().include?(matches.captures[6])
      raise "Timezone is invalid: '#{matches.captures[6]}'"
    end

    day_from = matches.captures[0].upcase
    day_to = matches.captures[1].upcase
    unless ([day_from, day_to] - WEEKDAYS).empty?
      raise "Day Range is invalid: '#{day_from}-#{day_to}'"
    end

    return matches.captures
  end

  def schedule_matches?(schedule)
    captures = parse_schedule(schedule)

    day_from = captures[0].upcase
    day_to = captures[1].upcase
    hour_from = captures[2].to_i
    hour_to = captures[4].to_i
    minute_from = captures[3].to_i
    minute_to = captures[5].to_i
    timezone = captures[6]

    begin
      current_time = Time.now.in_time_zone(timezone)
    rescue
      return false
    end

    day_matches = WEEKDAYS.index(current_time.strftime("%a").upcase).between?(WEEKDAYS.index(day_from), WEEKDAYS.index(day_to))
    current_minutes = (current_time.hour * 60) + current_time.min
    time_matches = current_minutes.between?((hour_from * 60) + minute_from, (hour_to * 60) + minute_to)

    return day_matches && time_matches
  end

end
