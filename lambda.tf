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

# ---------- Function 2: EBS snapshot ----------
data "archive_file" "ebs_snapshot" {
  type        = "zip"
  source_file = "${path.module}/lambda/ebs_snapshot.py"
  output_path = "${path.module}/build/ebs_snapshot.zip"
}

resource "aws_cloudwatch_log_group" "ebs_snapshot" {
  name              = "/aws/lambda/cost-guardian-ebs-snapshot"
  retention_in_days = 14
}

resource "aws_lambda_function" "ebs_snapshot" {
  function_name = "cost-guardian-ebs-snapshot"
  role          = aws_iam_role.ebs_snapshot.arn
  runtime       = "python3.13"
  handler       = "ebs_snapshot.handler"
  timeout       = 60

  filename         = data.archive_file.ebs_snapshot.output_path
  source_code_hash = data.archive_file.ebs_snapshot.output_base64sha256

  environment {
    variables = {
      BACKUP_TAG = "Backup"
    }
  }

  depends_on = [aws_cloudwatch_log_group.ebs_snapshot]
}

# ---------- Function 3: snapshot cleanup ----------
data "archive_file" "snapshot_cleanup" {
  type        = "zip"
  source_file = "${path.module}/lambda/snapshot_cleanup.py"
  output_path = "${path.module}/build/snapshot_cleanup.zip"
}

resource "aws_cloudwatch_log_group" "snapshot_cleanup" {
  name              = "/aws/lambda/cost-guardian-snapshot-cleanup"
  retention_in_days = 14
}

resource "aws_lambda_function" "snapshot_cleanup" {
  function_name = "cost-guardian-snapshot-cleanup"
  role          = aws_iam_role.snapshot_cleanup.arn
  runtime       = "python3.13"
  handler       = "snapshot_cleanup.handler"
  timeout       = 60

  filename         = data.archive_file.snapshot_cleanup.output_path
  source_code_hash = data.archive_file.snapshot_cleanup.output_base64sha256

  environment {
    variables = {
      RETENTION_DAYS = tostring(var.snapshot_retention_days)
      DRY_RUN        = tostring(var.dry_run)
    }
  }

  depends_on = [aws_cloudwatch_log_group.snapshot_cleanup]
}