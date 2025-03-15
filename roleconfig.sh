#!/bin/bash
echo "Creating our IAM Role 'MyAutomationRole', required for AWS Config auto remediation"
echo "Attaching the AmazonSSMAutomationRole AWS Managed Policy..."

# Creating the role and configuring the Trust Policy
echo "Creating the role and configuring the Trust Policy..."
iamRoleArn=$(aws iam create-role --role-name "MyAutomationRole" \
--assume-role-policy-document "$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "ec2.amazonaws.com",
                    "ssm.amazonaws.com"
                ]
            },
            "Action": [
                "sts:AssumeRole"
            ]
        }
    ]
}
EOF
)" --query "Role.Arn" --output=text)

# Error Handling: If IAM Role creation failed, exit
if [[ -z "$iamRoleArn" ]]; then
    echo "Error: IAM Role creation failed!"
    exit 1
fi

# Attaching the AmazonSSMAutomationRole AWS Managed Policy
echo "Attaching the AmazonSSMAutomationRole AWS Managed Policy..."
aws iam attach-role-policy --role-name "MyAutomationRole" \
 --policy-arn "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"

# Adding the inline policy which allows the role to be passed to another service
echo "Adding the inline policy which allows the role to be passed to another service..."
aws iam put-role-policy --role-name "MyAutomationRole" \
 --policy-name "AllowPassRole" \
 --policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
        {
            \"Effect\": \"Allow\",
            \"Action\": \"iam:PassRole\",
            \"Resource\": \"$iamRoleArn\"
        }
    ]
}"

# Finally, output the ARN of the role we created
echo "IAM Role successfully created! ARN: $iamRoleArn"
