apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: namespaced-nodepool-${namespace}
spec:
  template:
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      requirements:
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: ["on-demand"]
        - key: "node.kubernetes.io/instance-type"
          operator: In
          values: ["t3.medium"]
      taints:
        - key: namespace
          value: "${namespace}"
          effect: NoSchedule
      startupTaints:
        - key: "karpenter.sh/unregistered"
          effect: NoSchedule
  limits:
    cpu: 1000
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 30s
