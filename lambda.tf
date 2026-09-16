# ---------- Function 1: EC2 tag enforcer ----------
data "archive_file" "ec2_tag_enforcer" {
  type        = "zip"
  source_file = "${path.module}/lambda/ec2_tag_enforcer.py"
  output_path = "${path.module}/build/ec2_tag_enforcer.zip"
}

resource "aws_cloudwatch_log_group" "ec2_tag_enforcer" {
  name              = "/aws/lambda/cost-guardian-ec2-tag-enforcer"
  retention_in_days = 14
}

resource "aws_lambda_function" "ec2_tag_enforcer" {
  function_name = "cost-guardian-ec2-tag-enforcer"
  role          = aws_iam_role.ec2_tag_enforcer.arn
  runtime       = "python3.13"
  handler       = "ec2_tag_enforcer.handler"
  timeout       = 30

  filename         = data.archive_file.ec2_tag_enforcer.output_path
  source_code_hash = data.archive_file.ec2_tag_enforcer.output_base64sha256

  environment {
    variables = {
      REQUIRED_TAG = var.required_tag_key
      DRY_RUN      = tostring(var.dry_run)
    }
  }

  depends_on = [aws_cloudwatch_log_group.ec2_tag_enforcer]
}