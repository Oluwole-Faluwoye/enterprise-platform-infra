Networking and Security Groups for Pods

Application SG

Auth-service application SG:

sg-092eb850b231b34be

RDS SG:

sg-070e1746bace53b7b

EKS node SG:

sg-0e6a963d6bc0fd76b

Application SG egress

Added:

UDP/53 → VPC CIDR
TCP/53 → VPC CIDR
TCP/443 → 0.0.0.0/0
TCP/5432 → database SG

SG-for-Pods

VPC CNI is configured for pod ENIs.

The auth-service Helm chart creates a SecurityGroupPolicy.

The platform resolves the SG ID; the developer does not.

CoreDNS path

Because CoreDNS runs on EKS nodes, the node SG must permit DNS traffic
from application pod SGs:

Application SG
    ↓
Node SG
    ↓
CoreDNS

Both TCP/53 and UDP/53 are allowed.

Troubleshooting commands

nslookup <rds-host> 10.10.0.2

nc -vz <dns-ip> 53

nc -vzu -w 5 <dns-ip> 53

Direct CoreDNS pod/node tests are useful when the VPC resolver works but
Kubernetes DNS does not.