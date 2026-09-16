import os
from datetime import datetime, timedelta, timezone
import boto3

ec2 = boto3.client("ec2")

RETENTION_DAYS = int(os.environ.get("RETENTION_DAYS", "7"))
DRY_RUN = os.environ.get("DRY_RUN", "true").lower() == "true"


def handler(event, context):
    # Allow a manual test invoke to override retention; scheduled runs send {}
    retention_days = int(event.get("retention_days", RETENTION_DAYS))
    cutoff = datetime.now(timezone.utc) - timedelta(days=retention_days)

    # Only OUR snapshots: owned by this account AND signed with our tag
    response = ec2.describe_snapshots(
        OwnerIds=["self"],
        Filters=[{"Name": "tag:CreatedBy", "Values": ["cost-guardian"]}],
    )

    expired = [
        s["SnapshotId"] for s in response["Snapshots"] if s["StartTime"] < cutoff
    ]

    if not expired:
        print(f"No cost-guardian snapshots older than {retention_days} day(s).")
        return {"deleted": [], "dry_run": DRY_RUN}

    for snapshot_id in expired:
        if DRY_RUN:
            print(f"DRY RUN - would delete {snapshot_id}")
        else:
            ec2.delete_snapshot(SnapshotId=snapshot_id)
            print(f"Deleted {snapshot_id}")

    print(f"{'Would delete' if DRY_RUN else 'Deleted'} {len(expired)} snapshot(s) older than {retention_days} day(s).")
    return {"deleted": expired, "dry_run": DRY_RUN}