Configuring Route53 DNS for a Newly Purchased Domain
Overview

When using AWS Route53 to manage a newly purchased domain (e.g., from Namecheap), the domain registrar must delegate DNS management to Route53. This step is required before AWS Certificate Manager (ACM) can successfully validate SSL certificates.

This configuration is performed after Terraform creates the Route53 Hosted Zone.

Step 1: Deploy the Infrastructure

Run the infrastructure pipeline (or Terraform apply) to create the Route53 Hosted Zone.

Terraform creates:

Route53 Hosted Zone
DNS validation records for ACM
ACM Certificate request

At this point, the ACM certificate will typically remain in PENDING_VALIDATION until the domain is delegated to Route53.

Step 2: Retrieve the Route53 Name Servers
Sign in to the AWS Console.
Navigate to Route53.
Select Hosted Zones.
Open the hosted zone for your domain (e.g., dreammyles.online).
Locate the record with:
Type: NS
Open the NS record and copy the four Route53 nameservers.

Example:

ns-123.awsdns-45.com.
ns-678.awsdns-12.net.
ns-901.awsdns-34.org.
ns-456.awsdns-78.co.uk.

Note: Use the nameservers generated for your hosted zone. They are unique to your Route53 Hosted Zone.

Step 3: Update the Domain Registrar (Namecheap)
Log in to Namecheap.
Open Domain List.
Click Manage next to the domain.
Under Nameservers, select Custom DNS.
Enter the four Route53 nameservers obtained in Step 2.
Save the changes.
Step 4: Wait for DNS Propagation

DNS propagation may take anywhere from a few minutes to several hours.

During this period:

ACM will remain in PENDING_VALIDATION.
Terraform may continue waiting if certificate validation is part of the deployment.

Once AWS detects the validation CNAME records through the Route53 nameservers, the certificate status changes to:

ISSUED

Terraform will then complete successfully.

Step 5: Verify the Certificate

Check the ACM certificate status:

aws acm list-certificates --region us-east-1

or

aws acm describe-certificate \
  --certificate-arn <certificate-arn> \
  --region us-east-1

The certificate should show:

Status: ISSUED
Optional Verification

Verify that the domain is using the Route53 nameservers:

nslookup -type=ns dreammyles.online

or

dig NS dreammyles.online

The output should display the four AWS Route53 nameservers.

Recommended Deployment Workflow
Purchase the domain from the registrar (e.g., Namecheap).
Run the Terraform infrastructure deployment.
Allow Terraform to create:
Route53 Hosted Zone
ACM Certificate
ACM Validation DNS Records
Copy the Route53 NS records.
Update the domain's nameservers at the registrar.
Wait for DNS propagation.
ACM validates the certificate and changes its status to ISSUED.
Terraform completes the deployment.
Continue with the application deployment (ALB, ExternalDNS, ArgoCD, etc.).