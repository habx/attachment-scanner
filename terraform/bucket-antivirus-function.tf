resource "aws_lambda_function" "bucket-antivirus-function" {
  function_name = "bucket-antivirus-function"
  handler = "scan.lambda_handler"
  runtime = "python2.7"
  role = "${aws_iam_role.role_bucket-antivirus-function.arn}"
  filename = "../build/lambda.zip"
  source_code_hash = "${base64sha256(file("../build/lambda.zip"))}"
  memory_size = 1024
  timeout = 300
  environment = {
    variables = {
      AV_DEFINITION_S3_BUCKET = "clam-av-defintions" 
    }
  }
}

resource "aws_lambda_permission" "allow_trigger-scan" {
  action        = "lambda:InvokeFunction"
  statement_id  = "AllowScan"
  function_name = "${aws_lambda_function.bucket-antivirus-function.arn}"
  principal     = "s3.amazonaws.com"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "habx-email-production"
  lambda_function {
    lambda_function_arn = "${aws_lambda_function.bucket-antivirus-function.arn}"
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_iam_role" "role_bucket-antivirus-function" {
  name = "role_bucket-antivirus-function"
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

resource "aws_iam_role_policy" "role_policy_bucket-antivirus-function" {
  name = "role_policy_bucket-antivirus-function"
  role = "${aws_iam_role.role_bucket-antivirus-function.id}"
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
            "s3:*"
         ],
         "Effect":"Allow",
         "Resource":"*"
      }
   ]
}
EOF
}
