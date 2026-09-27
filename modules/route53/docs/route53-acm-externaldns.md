Route53, ACM and ExternalDNS

DNS ownership

Bootstrap owns:

dreammyles.online

and delegates:

dev.dreammyles.online

to a child Route53 zone.

ACM

DEV certificate covers:

*.dev.dreammyles.online
dev.dreammyles.online

The previous double-dev construction was corrected.

Auth hostname

api.dev.dreammyles.online

is therefore covered by the wildcard certificate.

GitOps

Terraform/Jenkins-derived certificate values are written into the
relevant Helm values.

Principle

Stable DNS ownership belongs to Bootstrap.

Environment workloads consume the delegated environment zone.