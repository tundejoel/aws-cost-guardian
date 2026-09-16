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