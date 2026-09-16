data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Trust policy shared by all four roles: only the Lambda service may assume them
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# ---------- Role 1: EC2 tag enforcer ----------
resource "aws_iam_role" "ec2_tag_enforcer" {
  name               = "cost-guardian-ec2-tag-enforcer-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "ec2_tag_enforcer" {
  # Describe* actions in EC2 do not support resource-level permissions,
  # so "*" is the only valid resource here.
  statement {
    sid       = "ReadInstances"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }

  # May stop instances ONLY if the required tag is absent.
  statement {
    sid     = "StopUntaggedOnly"
    actions = ["ec2:StopInstances"]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:instance/*"
    ]
    condition {
      test     = "Null"
      variable = "aws:ResourceTag/${var.required_tag_key}"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role_policy" "ec2_tag_enforcer" {
  name   = "ec2-tag-enforcer-permissions"
  role   = aws_iam_role.ec2_tag_enforcer.id
  policy = data.aws_iam_policy_document.ec2_tag_enforcer.json
}

resource "aws_iam_role_policy_attachment" "ec2_tag_enforcer_logs" {
  role       = aws_iam_role.ec2_tag_enforcer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------- Role 2: EBS snapshot ----------
resource "aws_iam_role" "ebs_snapshot" {
  name               = "cost-guardian-ebs-snapshot-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "ebs_snapshot" {
  statement {
    sid       = "ReadVolumes"
    actions   = ["ec2:DescribeVolumes"]
    resources = ["*"]
  }

  # CreateSnapshot touches two resources: the source volume and the new snapshot
  statement {
    sid     = "CreateSnapshots"
    actions = ["ec2:CreateSnapshot"]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:volume/*",
      "arn:aws:ec2:${data.aws_region.current.region}::snapshot/*"
    ]
  }

  # May tag snapshots ONLY as part of creating them - not re-tag existing resources
  statement {
    sid       = "TagOnlyOnCreate"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:${data.aws_region.current.region}::snapshot/*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateSnapshot"]
    }
  }
}

resource "aws_iam_role_policy" "ebs_snapshot" {
  name   = "ebs-snapshot-permissions"
  role   = aws_iam_role.ebs_snapshot.id
  policy = data.aws_iam_policy_document.ebs_snapshot.json
}

resource "aws_iam_role_policy_attachment" "ebs_snapshot_logs" {
  role       = aws_iam_role.ebs_snapshot.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------- Role 3: snapshot cleanup ----------
resource "aws_iam_role" "snapshot_cleanup" {
  name               = "cost-guardian-snapshot-cleanup-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "snapshot_cleanup" {
  statement {
    sid       = "ReadSnapshots"
    actions   = ["ec2:DescribeSnapshots"]
    resources = ["*"]
  }

  # May delete ONLY snapshots this system signed
  statement {
    sid       = "DeleteOwnSnapshotsOnly"
    actions   = ["ec2:DeleteSnapshot"]
    resources = ["arn:aws:ec2:${data.aws_region.current.region}::snapshot/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/CreatedBy"
      values   = ["cost-guardian"]
    }
  }
}

resource "aws_iam_role_policy" "snapshot_cleanup" {
  name   = "snapshot-cleanup-permissions"
  role   = aws_iam_role.snapshot_cleanup.id
  policy = data.aws_iam_policy_document.snapshot_cleanup.json
}

resource "aws_iam_role_policy_attachment" "snapshot_cleanup_logs" {
  role       = aws_iam_role.snapshot_cleanup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}