import os
from datetime import datetime, timezone
import boto3

ec2 = boto3.client("ec2")

BACKUP_TAG = os.environ.get("BACKUP_TAG", "Backup")


def handler(event, context):
    # Only volumes explicitly opted in with Backup=true
    response = ec2.describe_volumes(
        Filters=[{"Name": f"tag:{BACKUP_TAG}", "Values": ["true"]}]
    )
    volumes = response["Volumes"]

    if not volumes:
        print(f"No volumes tagged {BACKUP_TAG}=true. Nothing to snapshot.")
        return {"snapshots": []}

    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    created = []

    for volume in volumes:
        volume_id = volume["VolumeId"]
        snapshot = ec2.create_snapshot(
            VolumeId=volume_id,
            Description=f"cost-guardian nightly snapshot of {volume_id} on {today}",
            TagSpecifications=[{
                "ResourceType": "snapshot",
                "Tags": [
                    {"Key": "Name", "Value": f"{volume_id}-{today}"},
                    {"Key": "CreatedBy", "Value": "cost-guardian"},
                    {"Key": "SourceVolume", "Value": volume_id},
                ],
            }],
        )
        created.append(snapshot["SnapshotId"])
        print(f"Created {snapshot['SnapshotId']} from {volume_id}")

    print(f"Created {len(created)} snapshot(s).")
    return {"snapshots": created}