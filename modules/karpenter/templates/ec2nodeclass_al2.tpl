apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: Custom    # Don't change to AL2 (just use Custom with al2 ami id or alias) 
  amiSelectorTerms:
    - alias: al2@latest
    # - id: ami-0ce9a7e5952499323
  role: "${role}"
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery/${cluster_name}: "${cluster_name}"
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery/${cluster_name}: "${cluster_name}"
  userData: |
    #!/bin/bash
    /etc/eks/bootstrap.sh "${cluster_name}" --apiserver-endpoint "${api_server}" --b64-cluster-ca "${cluster_ca}" \
    --kubelet-extra-args '--register-with-taints "karpenter.sh/unregistered:NoExecute"'

  tags:
    karpenter.sh/discovery/${cluster_name}: "${cluster_name}"