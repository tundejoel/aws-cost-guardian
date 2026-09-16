# ---------- Schedule 1: EC2 tag enforcer, daily 02:00 UTC ----------
resource "aws_cloudwatch_event_rule" "ec2_tag_enforcer" {
  name                = "cost-guardian-ec2-tag-enforcer-daily"
  description         = "Stop EC2 instances missing the required tag"
  schedule_expression = "cron(0 2 * * ? *)"
}

resource "aws_cloudwatch_event_target" "ec2_tag_enforcer" {
  rule = aws_cloudwatch_event_rule.ec2_tag_enforcer.name
  arn  = aws_lambda_function.ec2_tag_enforcer.arn
}

resource "aws_lambda_permission" "ec2_tag_enforcer_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_tag_enforcer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_tag_enforcer.arn
}

# ---------- Schedule 2: EBS snapshot, nightly 01:00 UTC ----------
resource "aws_cloudwatch_event_rule" "ebs_snapshot" {
  name                = "cost-guardian-ebs-snapshot-nightly"
  description         = "Snapshot volumes tagged Backup=true"
  schedule_expression = "cron(0 1 * * ? *)"
}

resource "aws_cloudwatch_event_target" "ebs_snapshot" {
  rule = aws_cloudwatch_event_rule.ebs_snapshot.name
  arn  = aws_lambda_function.ebs_snapshot.arn
}

resource "aws_lambda_permission" "ebs_snapshot_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ebs_snapshot.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ebs_snapshot.arn
}

# ---------- Schedule 3: snapshot cleanup, nightly 03:00 UTC ----------
resource "aws_cloudwatch_event_rule" "snapshot_cleanup" {
  name                = "cost-guardian-snapshot-cleanup-nightly"
  description         = "Delete cost-guardian snapshots older than the retention window"
  schedule_expression = "cron(0 3 * * ? *)"
}

resource "aws_cloudwatch_event_target" "snapshot_cleanup" {
  rule = aws_cloudwatch_event_rule.snapshot_cleanup.name
  arn  = aws_lambda_function.snapshot_cleanup.arn
}

resource "aws_lambda_permission" "snapshot_cleanup_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.snapshot_cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.snapshot_cleanup.arn
}