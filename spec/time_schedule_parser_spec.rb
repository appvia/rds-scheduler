# frozen_string_literal: true

require 'spec_helper'
require 'time_schedule_parser'

describe TimeScheduleParser do
  describe 'attribute accessors' do
    it 'should have weekdays defined' do
      expect(TimeScheduleParser::WEEKDAYS).to eq(%w[MON TUE WED THU FRI SAT SUN])
    end
  end

  describe '#parse_schedule' do
    context 'when schedule is blank' do
      it 'should raise an error for a regex match failure' do
        schedule = ''
        expect { subject.parse_schedule(schedule) }.to raise_error(StandardError, 'Schedule does not match regex')
      end
    end

    context 'when schedule does not match the time definition pattern' do
      it 'should raise an error for a regex match failure' do
        schedule = 'MON-FRI 9-6 Europe/London'
        expect { subject.parse_schedule(schedule) }.to raise_error(StandardError, 'Schedule does not match regex')
      end
    end

    context 'when schedule has an invalid timezone' do
      it 'should raise an error for an invalid timezone' do
        schedule = 'MON-FRI 09:00-18:00 LDN'
        expect { subject.parse_schedule(schedule) }.to raise_error(TimeScheduleParser::TimezoneInvalid, "Timezone is invalid: 'LDN'")
      end
    end

    context 'when schedule has an invalid day range' do
      it 'should raise an error for an invalid day range' do
        schedule = 'MON-FRY 09:00-18:00 Europe/London'
        expect { subject.parse_schedule(schedule) }.to raise_error(StandardError, "Day Range is invalid: 'MON-FRY'")
      end
    end

    context 'with a valid uptime schedule' do
      it 'should return the parsed time schedule' do
        schedule = 'MON-FRI 09:00-18:00 Europe/London'
        ex = subject.time_schedule(day_from: 'MON', day_to: 'FRI', hour_from: 9, minute_from: 0, hour_to: 18, minute_to: 0, timezone: 'Europe/London')
        expect(subject.parse_schedule(schedule)).to eq(ex)
      end
    end
  end

  describe '#schedule_active?' do
    context 'when timezone is invalid' do
      it 'should return an error' do
        sch = subject.time_schedule(day_from: 'MON', day_to: 'FRI', hour_from: 9, minute_from: 0, hour_to: 18, minute_to: 0, timezone: 'LDN')
        expect { subject.schedule_active?(sch) }.to raise_error(TimeScheduleParser::TimezoneInvalid, "Current time could not be computed with the given timezone: 'LDN'")
      end
    end

    context 'when current day is outside of schedule' do
      it 'should return false' do
        time_now = Time.parse('2019-01-05 14:00')
        allow(Time).to receive(:now).and_return(time_now)
        sch = subject.time_schedule(day_from: 'MON', day_to: 'FRI', hour_from: 9, minute_from: 0, hour_to: 18, minute_to: 0, timezone: 'Europe/London')
        expect(subject.schedule_active?(sch)).to be false
      end
    end

    context 'when current time is outside of schedule' do
      it 'should return false' do
        time_now = Time.parse('2019-01-04 08:59')
        allow(Time).to receive(:now).and_return(time_now)
        sch = subject.time_schedule(day_from: 'MON', day_to: 'FRI', hour_from: 9, minute_from: 0, hour_to: 18, minute_to: 0, timezone: 'Europe/London')
        expect(subject.schedule_active?(sch)).to be false
      end
    end

    context 'when current time is within the schedule' do
      it 'should return true' do
        time_now = Time.parse('2019-01-04 09:00')
        allow(Time).to receive(:now).and_return(time_now)
        sch = subject.time_schedule(day_from: 'MON', day_to: 'FRI', hour_from: 9, minute_from: 0, hour_to: 18, minute_to: 0, timezone: 'Europe/London')
        expect(subject.schedule_active?(sch)).to be true
      end
    end
  end
end
