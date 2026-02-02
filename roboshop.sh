#!/bin/bash

SG_ID="sg-0fc8a83e866144bd7"
AMI_ID="ami-0220d79f3f480ecf5"
HOSTEDZONE_ID="Z04814222XKMSD20FJS7N"
DOMAIN_NAME="exploreops.online"



for instance in $@
do
    INSTANCE_ID=$( aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type "t3.micro" \
  --security-group-ids $SG_ID \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
  --query 'Instances[0].InstanceId' \
  --output text )

if [ $instance == "frontend" ]; then
    IP=$(
        aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query "Reservations[].Instances[].PublicIpAddress" \
        --output text
    )
        RECORD_NAME="$DOMAIN_NAME"
    else
        IP=$(
        aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query "Reservations[].Instances[].PrivateIpAddress" \
        --output text
    )
    RECORD_NAME="$instance.$DOMAIN_NAME"
fi

echo "IP Address: $IP"

aws route53 change-resource-record-sets \
--hosted-zone-id $HOSTEDZONE_ID \
--change-batch '
{
  "Comment": "Updating record",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "'$RECORD_NAME'",
        "Type": "A",
        "TTL": 1,
        "ResourceRecords": [
          {
            "Value": "'$IP'"
          }
        ]
      }
    }
  ]
}

'
echo "record updated for $instance"

done