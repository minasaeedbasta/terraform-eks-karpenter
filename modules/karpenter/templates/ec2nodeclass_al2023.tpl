apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2023
  amiSelectorTerms:
    - alias: al2023@latest
  role: "${role}"
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery/${cluster_name}: "${cluster_name}"
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery/${cluster_name}: "${cluster_name}"
  userData: |
     apiVersion: node.eks.aws/v1alpha1
     kind: NodeConfig
     spec:
       cluster:
         apiServerEndpoint: "${api_server}"
         certificateAuthority: "${cluster_ca}"
         name: "${cluster_name}"
       kubelet:
         config:
           maxPods: 110
         flags:
         - --node-labels="karpenter.sh/capacity-type=on-demand"
  tags:
    karpenter.sh/discovery/${cluster_name}: "${cluster_name}"