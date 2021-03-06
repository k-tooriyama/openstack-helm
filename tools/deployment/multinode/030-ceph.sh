#!/bin/bash

# Copyright 2017 The Openstack-Helm Authors.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

set -xe

#NOTE: Deploy command
uuidgen > /tmp/ceph-fs-uuid.txt
CEPH_PUBLIC_NETWORK="$(./tools/deployment/multinode/kube-node-subnet.sh)"
CEPH_CLUSTER_NETWORK="$(./tools/deployment/multinode/kube-node-subnet.sh)"
CEPH_FS_ID="$(cat /tmp/ceph-fs-uuid.txt)"
tee /tmp/ceph.yaml << EOF
endpoints:
  identity:
    namespace: openstack
  object_store:
    namespace: ceph
  ceph_mon:
    namespace: ceph
network:
  public: ${CEPH_PUBLIC_NETWORK}
  cluster: ${CEPH_CLUSTER_NETWORK}
deployment:
  storage_secrets: true
  ceph: true
  rbd_provisioner: true
  cephfs_provisioner: true
  client_secrets: false
  rgw_keystone_user_and_endpoints: false
bootstrap:
  enabled: true
conf:
  config:
    global:
      fsid: ${CEPH_FS_ID}
  rgw_ks:
    enabled: true
EOF
helm upgrade --install ceph ./ceph \
  --namespace=ceph \
  --values=/tmp/ceph.yaml

#NOTE: Wait for deploy
./tools/deployment/common/wait-for-pods.sh ceph 1200

#NOTE: Validate Deployment info
helm status ceph
