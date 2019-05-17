# RDS Scheduler

[![Build_Status](https://circleci.com/gh/appvia/rds-scheduler.svg?style=svg)](https://circleci.com/gh/appvia/rds-scheduler) [![Docker Repository on Quay](https://quay.io/repository/appvia/rds-scheduler/status "Docker Repository on Quay")](https://quay.io/repository/appvia/rds-scheduler)

Manage uptime schedules for RDS Instances and shutdown instances outside of working hours.

All RDS instances are checked for a given AWS Tag, `appvia.io/rds-scheduler/uptime-schedule`, to determine whether they need to be managed according to a specified uptime schedule. If the AWS Tag is not found, no action is taken on that DB instance.

The value of an AWS Tag should hold a time definition matching the pattern: `<WEEKDAY-FROM>-<WEEKDAY-TO> <HH:MM-FROM>-<HH:MM-TO> <TIMEZONE>` with the week definition running from Monday => Sunday.

Example use:
```yml
# Keep RDS online from Monday 08:30 until Friday 18:00, and shutdown at all other times
appvia.io/rds-scheduler/uptime-schedule: MON-FRI 08:30-18:00 Europe/London
```

OR alternatively:
```yml
# Shutdown RDS from Friday 18:00 through to Sunday 20:00
appvia.io/rds-scheduler/downtime-schedule: FRI-SUN 18:00-20:00 Europe/London
```

## Usage

Set the Tag `appvia.io/rds-scheduler/uptime-schedule` (or `appvia.io/rds-scheduler/downtime-schedule`) on each RDS instance, providing a time definition as described above.

Run the docker container, providing AWS Credentials either as environment variables or mounting in your AWS config directory, e.g.:

```bash
# Pass as environment variables
docker run --rm -t -e AWS_ACCESS_KEY_ID=X AWS_SECRET_ACCESS_KEY=X -e AWS_REGION=eu-west-2 quay.io/appvia/rds-scheduler

# Use AWS config and profile
docker run --rm -t -v ~/.aws:/home/app/.aws:ro -e AWS_PROFILE=my-aws-profile quay.io/appvia/rds-scheduler
```

### Configuration

The following environment variables can be passed:
- `DRY_RUN`: Don't make any changes to RDS instances, just prints what actions would be performed to stdout (default: `false`)
- `LOOP_INTERVAL_SECS`: How frequently (in seconds) to loop and perform checks on the RDS instance schedules (default: `60`)
- `RUN_ONCE`: Loop through RDS instances only once and exit the script (default: `false`)
- `TAG_UPTIME_SCHEDULE`: AWS Tag name on the RDS instances containing a time definition (default: `appvia.io/rds-scheduler/uptime-schedule`)
- `TAG_DOWNTIME_SCHEDULE`: AWS Tag name on the RDS instances containing a time definition (default: `appvia.io/rds-scheduler/downtime-schedule`)

### Kubernetes

The RDS Scheduler can run within your Kubernetes Cluster as a lightweight deployment. Review the [./examples/kube](./examples/kube) directory for example deployment files.

### Lambda

The RDS Scheduler can be configured to run as a Lambda Function within your AWS Account.

There are some things to note when attempting to run in Lambda:
- The file to be executed is at the root of the zipfile being uploaded
- The dependencies are packaged within the zipfile at `./vendor/bundle/ruby/2.5.0/...` (AWS Lambda uses Ruby v2.5.0)

If you're using **[rbenv](https://github.com/rbenv/rbenv)**:
```bash
# Install Ruby v2.5.0
rbenv install 2.5.0

# Install / Update bundler
gem install bundler

# Download dependencies
bundle install --path=lib/vendor/bundle --deployment --without test

# Copy Gemfiles to the lib directory
cp Gemfile* lib/
```

Example deployment files are located in the [./examples/terraform](./examples/terraform) directory. The Lambda Function is configured to trigger via a CloudWatch Event Rule and execute every 5 minutes.

All log output of the Lambda Function is recorded under a CloudWatch Log Group, keeping the same name as the Function (`rds-scheduler`). This is accessible under the following URL (replace with the relevant AWS region): `https://eu-west-2.console.aws.amazon.com/cloudwatch/home?region=eu-west-2#logStream:group=/aws/lambda/rds-scheduler`

## IAM Permissions

For the RDS Scheduler to function properly, the following IAM Statement is required:
```json
{
    "Effect": "Allow",
    "Action": [
        "rds:DescribeDBInstances",
        "rds:ListTagsForResource",
        "rds:StartDBInstance",
        "rds:StopDBInstance"
    ],
    "Resource": "*"
}
```
