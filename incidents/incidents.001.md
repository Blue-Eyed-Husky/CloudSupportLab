## Failure scenario SSH failure 1



Summary: SSH ingress rule was removed from Security Group. Upon attempting to access the EC2 via SSH, the user timed out.

Symptom: User timed out when attempting to SSH into the instance.

Impact: Only impacted the lab user leading to low level severity. If more were affected then medium/high.

Diagnosis:
 Must check to confirm instance IP is correct
 Are route tables and internet gateway available
 Are there inbound rules in Security Group to allow port 22 SSH.

Evidence:
 Terraform output instance\_state = "running"
 AWS console check:
 EC2 console -> instance -> Cloud lab instance = "running"
 EC2 console -> Security Groups -> SSH ingress for port 22 missing/removed from user CIDR source
 VPC console -> Subnets -> route table -> 0.0.0.0/0 through IGW
 VPC console -> internet gateway -> attached to VPC

Root Cause:
 Security Group inbound rule allowing SSH (TCP 22) from my source CIDR was not present, causing inbound packets to be dropped at the SG.

Fix:
 Restored inbound rule TCP 22 from user CIDR via terraform and ran terraform apply.

Lessons
 Learned a timeout means port 22 may be misplaced or missing meaning inbound traffic stalled once it reached the Security Group leading to timeout error. It was as if the building was open but the gate was locked preventing the user from reaching the front door.

Validation:
 SSH access restored successfully after applying the SG inbound rules.

