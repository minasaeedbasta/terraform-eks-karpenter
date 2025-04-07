apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: admin-binding
  namespace: ${namespace}
subjects:
  - kind: Group
    name: ${group_name}
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: ${role_name}
  apiGroup: rbac.authorization.k8s.io
