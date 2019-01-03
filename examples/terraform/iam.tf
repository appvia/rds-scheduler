# Define an IAM role for the lambda function to use for AWS RDS access
resource "aws_iam_role" "rds-scheduler" {
  name               = "rds-scheduler-lambda"
  assume_role_policy = "${data.aws_iam_policy_document.lambda-assume-role.json}"
}

# An assume-role policy allowing the Lambda service to assume it
data "aws_iam_policy_document" "lambda-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# IAM policy document defining the access required to RDS resources
data "aws_iam_policy_document" "lambda-rds-access" {
  statement {
    actions   = ["rds:DescribeDBInstances", "rds:ListTagsForResource", "rds:StartDBInstance", "rds:StopDBInstance"]
    resources = ["*"]
  }
}

# Attach RDS access policy document
resource "aws_iam_policy" "lambda-rds-access" {
  name        = "rds-scheduler-rds-access"
  description = "IAM Policy to allow RDS access"
  policy      = "${data.aws_iam_policy_document.lambda-rds-access.json}"
}

# Attach RDS policy to lambda role
resource "aws_iam_role_policy_attachment" "lambda-rds-access" {
  role       = "${aws_iam_role.rds-scheduler.name}"
  policy_arn = "${aws_iam_policy.lambda-rds-access.arn}"
}

# IAM policy document defining the access required to write log streams to CloudWatch
data "aws_iam_policy_document" "lambda-cloudwatch-logging" {
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
}

# Attach CloudWatch logging policy document
resource "aws_iam_policy" "lambda-cloudwatch-logging" {
  name        = "rds-scheduler-cloudwatch-logging"
  description = "IAM Policy to allow logging to CloudWatch"
  policy      = "${data.aws_iam_policy_document.lambda-cloudwatch-logging.json}"
}

# Attach CloudWatch policy to lambda role
resource "aws_iam_role_policy_attachment" "lambda-cloudwatch-logging" {
  role       = "${aws_iam_role.rds-scheduler.name}"
  policy_arn = "${aws_iam_policy.lambda-cloudwatch-logging.arn}"
}
