apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: ${namespace}
  name: admin
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]