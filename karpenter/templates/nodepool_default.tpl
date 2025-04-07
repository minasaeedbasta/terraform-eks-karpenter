apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
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
        - key: example.com/special-taint
          effect: NoSchedule
      startupTaints:
        - key: "karpenter.sh/unregistered"
          effect: NoSchedule
  limits:
    cpu: 1000
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s