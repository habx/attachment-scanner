resource "aws_lambda_function" "bucket-antivirus-update" {
  function_name = "bucket-antivirus-update"
  handler = "update.lambda_handler"
  runtime = "python2.7"
  role = "${aws_iam_role.role_bucket-antivirus-update.arn}"
  filename = "../build/lambda.zip"
  source_code_hash = "${base64sha256(file("../build/lambda.zip"))}"
  memory_size = 512
  timeout = 300
  environment = {
    variables = {
      AV_DEFINITION_S3_BUCKET = "clam-av-defintions" 
    }
  }
}

resource "aws_lambda_permission" "allow_trigger-update" {
  action        = "lambda:InvokeFunction"
  statement_id  = "AllowUpdate"
  function_name = "${aws_lambda_function.bucket-antivirus-update.arn}"
  principal     = "events.amazonaws.com"
}

resource "aws_cloudwatch_event_rule" "every_3_hours" {
  name = "every_3_hours"
  schedule_expression = "rate(3 hours)" 
}

resource "aws_cloudwatch_event_target" "bucket-antivirus-update" {
  rule      = "${aws_cloudwatch_event_rule.every_3_hours.name}"
  arn       = "${aws_lambda_function.bucket-antivirus-update.arn}"
}

resource "aws_iam_role" "role_bucket-antivirus-update" {
  name = "role_bucket-antivirus-update"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "role_policy_bucket-antivirus-update" {
  name = "role_policy_bucket-antivirus-update"
  role = "${aws_iam_role.role_bucket-antivirus-update.id}"
  policy = <<EOF
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":[
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
         ],
         "Resource":"*"
      },
      {
         "Action":[
            "s3:GetObject",
            "s3:GetObjectTagging",
            "s3:PutObject",
            "s3:PutObjectTagging",
            "s3:PutObjectVersionTagging"
         ],
         "Effect":"Allow",
         "Resource":"arn:aws:s3:::clam-av-defintions/*"
      }
   ]
}
EOF
}
