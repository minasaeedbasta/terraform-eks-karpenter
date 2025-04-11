apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: ${node-pool-name}
spec:
  template:
    metadata:
      labels:
        node-pool: "${node-pool-name}"
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
          values: [${instance_type}]
      taints:
        - key: node-pool
          value: ${node-pool-name}
          effect: NoSchedule
  limits:
    cpu: ${maxRunners * 2}
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 60s