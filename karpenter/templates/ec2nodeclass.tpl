apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: Custom  # Capitalized as per Karpenter spec
  amiSelectorTerms:
    - id: "${custom_ami_id}"
  role: "${role}"
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${cluster_name}"
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${cluster_name}"
  userData: |
    #!/bin/bash
    set -o xtrace
    /etc/eks/bootstrap.sh ${cluster_name} \
      --apiserver-endpoint '${cluster_endpoint}' \
      --b64-cluster-ca '${cluster_ca_data}' \
      --kubelet-extra-args '--node-labels=karpenter.sh/discovery=${cluster_name},node.kubernetes.io/lifecycle=spot,karpenter.sh/controller=true,karpenter.sh/provisioned=true --register-with-taints=karpenter.sh/unregistered:NoExecute'
  tags:
    karpenter.sh/discovery: "${cluster_name}"