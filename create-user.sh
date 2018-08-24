#!/bin/bash

set -e

if [[ $# == 0 ]]; then
  echo "Usage: $0 SERVICEACCOUNT NAMESPACE CLUSTERROLE" >&2
  echo "" >&2
  echo "This script creates a user(serviceaccount) in a specific namespace with a selected clusterrole and then its  generate the kubeconfig to access the apiserver with the specified serviceaccount and outputs it to stdout." >&2

  exit 1
fi

# Create serviceaccount!
USERTEMPLATE=$(mktemp user.XXXXXXXXX)
echo "Creating user template $USERTEMPLATE"
cat <<< "
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $1
  namespace: $2" > $USERTEMPLATE

echo "Creating user $1 at $2 namespace"
USEROUTPUT=$(kubectl create -f $USERTEMPLATE)
echo $USEROUTPUT

# Adding role
USERROLE=$(mktemp userrole.XXXXXXXXX)
echo "Creating rolebinding template $USERROLE"
cat <<< "
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: edit-permission-poc
  namespace: $2
subjects:
- kind: ServiceAccount
  name: $1
  namespace: $2
roleRef:
  kind: ClusterRole
  name: $3
  apiGroup: rbac.authorization.k8s.io" > $USERROLE

echo "Creating rolebinding $1 at $2 namespace with ClusterRole $3"
USEROUTPUT=$(kubectl create -f $USERROLE)
echo $USERROLE

# Creating kubeconfig credential!

KUBECONFIG=$(mktemp kubeconfig.XXXXXXXXX)
echo "Creating rolebinding template $USERROLE"
CREDENTIAL=$(bash create-kubeconfig $1 -n $2)
echo "La credencial es:"
echo $CREDENTIAL
cat $CREDENTIAL > $KUBECONFIG