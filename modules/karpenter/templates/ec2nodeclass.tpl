apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily:  Bottlerocket
  amiSelectorTerms:
    - id: "${custom_ami_id}"
  role: "${role}"
  subnetSelectorTerms:
    - tags:
        "karpenter.sh/discovery/${cluster_name}": "${cluster_name}"
  securityGroupSelectorTerms:
    - tags:
        "karpenter.sh/discovery/${cluster_name}": "${cluster_name}"
  userData: |
    [settings.kubernetes]
      api-server = "${api_server}"
      cluster-certificate = "${cluster_ca}"
      cluster-name = "${cluster_name}"
  tags:
    "karpenter.sh/discovery/${cluster_name}": "${cluster_name}"