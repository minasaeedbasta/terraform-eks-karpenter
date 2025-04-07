apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: "enforce-namespace-taint-${namespace}"
spec:
  rules:
    - name: "enforce-toleration-for-namespace-${namespace}"
      match:
        resources:
          kinds:
            - Pod
      mutate:
        patchStrategicMerge:
          spec:
            tolerations:
              - key: "kubernetes.io/namespace"
                operator: "Equal"
                value: "${namespace}"
                effect: "NoSchedule"
