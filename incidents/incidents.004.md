## Failure Incident 4 - IAM Failure



# Summary

User was unable to access the s3 bucket cho-cloud-s3-bucket via instance. Instance permissions were removed/lost resulting in AccessDenied while the instance remained running and authenticated via its instance profile role.



# Symptom

attempting access the S3 bucket through the instance was denied

SSH into the instance -> aws s3 ls s3://cho-cloud-s3-bucket -> ":An error occurred (AccessDenied) when calling the ListObjectsV2 operation: User: arn:aws:sts::011839104314:assumed-role/cloud\_lab\_instance\_role/i-035796ce0c5c96e9a is not authorized to perform: s3:ListBucket on resource: "arn:aws:s3:::cho-cloud-s3-bucket" because no identity-based policy allows the s3:ListBucket action"



# Impact

user unable to access s3 bucket - severity low



# Diagnosis

logged into terminal 

command 1: aws sts get-caller-identity -> expected ARN appeared "arn:aws:iam::011839104314:instance-profile/cloud\_lab\_instance\_profile"

command 2: aws iam list-attached-role-policies --role-name cloud\_lab\_instance\_profile = An error occurred (NoSuchEntity) when calling the ListAttachedRolePolicies operation: The role with name cloud\_lab\_instance\_profile cannot be found.

&nbsp;	Confirming s3 access policy was not included in IAM role policy attachment



# Root Cause

Instance not able to access S3 bucket due to the removal/loss of IAM permissions of the S3 bucket. 



# Fix 

Restored required S3 permissions via IAM policy role attachment to S3 bucket. 

Terraform apply --auto-approve



# Validation

Following SSH into the instance, S3 bucket was accessible. 

aws s3 ls s3://cho-cloud-s3-bucket

aws s3 ls s3://cho-cloud-s3-bucket/iam/
