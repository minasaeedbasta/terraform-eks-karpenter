apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: ${node_pool_name}
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
        - key: node-pool
          value: runners
          effect: NoSchedule
  limits:
    cpu: ${max_runners * 2}
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s