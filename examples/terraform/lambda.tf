# Zip up the rds-scheduler code and dependencies
data "archive_file" "rds-scheduler" {
  type        = "zip"
  source_dir  = "../../src"
  output_path = "build/rds-scheduler.zip"
}

# Define the AWS Lambda function, which uploads the code package
resource "aws_lambda_function" "rds-scheduler" {
  filename         = "../build/rds-scheduler.zip"
  source_code_hash = "${data.archive_file.rds-scheduler.output_base64sha256}"
  function_name    = "rds-scheduler"
  role             = "${aws_iam_role.rds-scheduler.arn}"
  description      = "RDS Scheduler to start/stop instances"
  handler          = "lambda.main"
  runtime          = "ruby2.5"
  timeout          = 10

  environment {
    variables = {
      AWS_REGION = "eu-west-2"
      RUN_ONCE   = "true"
    }
  }
}

# Define a schedule to run every 5 minutes
resource "aws_cloudwatch_event_rule" "every-five-minutes" {
  name                = "rds-scheduler-every-five-minutes"
  description         = "Fires every five minutes"
  schedule_expression = "rate(5 minutes)"
}

# Set the CloudWatch event to target the Lambda function when it triggers
resource "aws_cloudwatch_event_target" "rds-scheduler-every-five-minutes" {
  rule      = "${aws_cloudwatch_event_rule.every-five-minutes.name}"
  target_id = "rds-scheduler"
  arn       = "${aws_lambda_function.rds-scheduler.arn}"
}

# Add permissions to allow the CloudWatch event to call the Lambda function
resource "aws_lambda_permission" "rds-scheduler" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.rds-scheduler.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.every-five-minutes.arn}"
}
