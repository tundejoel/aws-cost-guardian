import os
import boto3

ec2 = boto3.client("ec2")

REQUIRED_TAG = os.environ.get("REQUIRED_TAG", "Project")
DRY_RUN = os.environ.get("DRY_RUN", "true").lower() == "true"


def handler(event, context):
    # Only running instances - no point stopping what is already stopped
    response = ec2.describe_instances(
        Filters=[{"Name": "instance-state-name", "Values": ["running"]}]
    )

    offenders = []
    for reservation in response["Reservations"]:
        for instance in reservation["Instances"]:
            tags = {t["Key"]: t["Value"] for t in instance.get("Tags", [])}
            if REQUIRED_TAG not in tags:
                offenders.append(instance["InstanceId"])

    if not offenders:
        print(f"All running instances carry the '{REQUIRED_TAG}' tag. Nothing to do.")
        return {"stopped": [], "dry_run": DRY_RUN}

    if DRY_RUN:
        print(f"DRY RUN - would stop {len(offenders)} instance(s) missing '{REQUIRED_TAG}': {offenders}")
    else:
        ec2.stop_instances(InstanceIds=offenders)
        print(f"Stopped {len(offenders)} instance(s) missing '{REQUIRED_TAG}': {offenders}")

    return {"stopped": offenders, "dry_run": DRY_RUN}