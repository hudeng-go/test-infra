#!/usr/bin/env bash
# Copyright 2021 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

dir="$(dirname "${BASH_SOURCE[0]}")"

for release in "$@"; do
  output="${dir}/release-${release}.yaml"
  orchestrator_release="${release}"
  kubernetes_version="latest"

  if [[ "${release}" == "master" ]]; then
    branch="master"
    orchestrator_release="1.21"
  else
    branch="release-${release}"
    kubernetes_version+="-${release}"
  fi

  cat >"${output}" <<EOF
# generated by ./config/jobs/kubernetes/sig-cloud-provider/azure/generate.sh.
presubmits:
  kubernetes/kubernetes:
  - name: pull-kubernetes-e2e-aks-engine-conformance
    decorate: true
    always_run: false
    optional: true
    run_if_changed: 'azure.*\.go'
    path_alias: k8s.io/kubernetes
    branches:
    - ${branch}
    labels:
      preset-service-account: "true"
      preset-azure-cred: "true"
      preset-dind-enabled: "true"
    spec:
      containers:
      - image: gcr.io/k8s-testimages/kubekins-e2e:v20210412-176e4b6-${release}
        command:
        - runner.sh
        - kubetest
        args:
        # Generic e2e test args
        - --test
        - --up
        - --down
        - --build=quick
        - --dump=\$(ARTIFACTS)
        # Azure-specific test args
        - --provider=skeleton
        - --deployment=aksengine
        - --aksengine-agentpoolcount=2
        - --aksengine-admin-username=azureuser
        - --aksengine-creds=\$(AZURE_CREDENTIALS)
        - --aksengine-orchestratorRelease=${orchestrator_release}
        - --aksengine-mastervmsize=Standard_DS2_v2
        - --aksengine-agentvmsize=Standard_DS2_v2
        - --aksengine-deploy-custom-k8s
        - --aksengine-location=westus2
        - --aksengine-public-key=\$(AZURE_SSH_PUBLIC_KEY_FILE)
        - --aksengine-template-url=https://raw.githubusercontent.com/kubernetes-sigs/cloud-provider-azure/master/tests/k8s-azure/manifest/kubernetes.json
        - --aksengine-download-url=https://github.com/Azure/aks-engine/releases/download/nightly/aks-engine-nightly-linux-amd64.tar.gz
        # Specific test args
        - --test_args=--ginkgo.focus=\[Conformance\] --ginkgo.skip=\[Serial\]
        - --ginkgo-parallel=30
        securityContext:
          privileged: true

  - name: pull-kubernetes-e2e-aks-engine-azure-disk-vmas
    decorate: true
    always_run: false
    optional: true
    run_if_changed: 'azure.*\.go'
    path_alias: k8s.io/kubernetes
    branches:
    - ${branch}
    labels:
      preset-service-account: "true"
      preset-azure-cred: "true"
      preset-dind-enabled: "true"
    extra_refs:
    - org: kubernetes-sigs
      repo: azuredisk-csi-driver
      base_ref: master
      path_alias: sigs.k8s.io/azuredisk-csi-driver
    spec:
      containers:
      - image: gcr.io/k8s-testimages/kubekins-e2e:v20210412-176e4b6-${release}
        command:
        - runner.sh
        - kubetest
        args:
        # Generic e2e test args
        - --test
        - --up
        - --down
        - --build=quick
        - --dump=\$(ARTIFACTS)
        # Azure-specific test args
        - --provider=skeleton
        - --deployment=aksengine
        - --aksengine-admin-username=azureuser
        - --aksengine-creds=\$(AZURE_CREDENTIALS)
        - --aksengine-orchestratorRelease=${orchestrator_release}
        - --aksengine-deploy-custom-k8s
        - --aksengine-location=westus2
        - --aksengine-public-key=\$(AZURE_SSH_PUBLIC_KEY_FILE)
        - --aksengine-template-url=https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/master/test/e2e/manifest/in-tree.json
        - --aksengine-download-url=https://github.com/Azure/aks-engine/releases/download/nightly/aks-engine-nightly-linux-amd64.tar.gz
        # Specific test args
        - --test-azure-disk-csi-driver
        securityContext:
          privileged: true
        env:
        - name: AZURE_STORAGE_DRIVER
          value: "kubernetes.io/azure-disk" # In-tree Azure disk storage class

  - name: pull-kubernetes-e2e-aks-engine-azure-disk-vmss
    decorate: true
    always_run: false
    optional: true
    run_if_changed: 'azure.*\.go'
    path_alias: k8s.io/kubernetes
    branches:
    - ${branch}
    labels:
      preset-service-account: "true"
      preset-azure-cred: "true"
      preset-dind-enabled: "true"
    extra_refs:
    - org: kubernetes-sigs
      repo: azuredisk-csi-driver
      base_ref: master
      path_alias: sigs.k8s.io/azuredisk-csi-driver
    spec:
      containers:
      - image: gcr.io/k8s-testimages/kubekins-e2e:v20210412-176e4b6-${release}
        command:
        - runner.sh
        - kubetest
        args:
        # Generic e2e test args
        - --test
        - --up
        - --down
        - --build=quick
        - --dump=\$(ARTIFACTS)
        # Azure-specific test args
        - --provider=skeleton
        - --deployment=aksengine
        - --aksengine-admin-username=azureuser
        - --aksengine-creds=\$(AZURE_CREDENTIALS)
        - --aksengine-orchestratorRelease=${orchestrator_release}
        - --aksengine-deploy-custom-k8s
        - --aksengine-location=westus2
        - --aksengine-public-key=\$(AZURE_SSH_PUBLIC_KEY_FILE)
        - --aksengine-template-url=https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/master/test/e2e/manifest/in-tree-vmss.json
        - --aksengine-download-url=https://github.com/Azure/aks-engine/releases/download/nightly/aks-engine-nightly-linux-amd64.tar.gz
        # Specific test args
        - --test-azure-disk-csi-driver
        securityContext:
          privileged: true
        env:
        - name: AZURE_STORAGE_DRIVER
          value: "kubernetes.io/azure-disk" # In-tree Azure disk storage class
        - name: ENABLE_TOPOLOGY
          value: "true"

  - name: pull-kubernetes-e2e-aks-engine-azure-file
    decorate: true
    always_run: false
    optional: true
    run_if_changed: 'azure.*\.go'
    path_alias: k8s.io/kubernetes
    branches:
    - ${branch}
    labels:
      preset-service-account: "true"
      preset-azure-cred: "true"
      preset-dind-enabled: "true"
    extra_refs:
    - org: kubernetes-sigs
      repo: azurefile-csi-driver
      base_ref: master
      path_alias: sigs.k8s.io/azurefile-csi-driver
    spec:
      containers:
      - image: gcr.io/k8s-testimages/kubekins-e2e:v20210412-176e4b6-${release}
        command:
        - runner.sh
        - kubetest
        args:
        # Generic e2e test args
        - --test
        - --up
        - --down
        - --build=quick
        - --dump=\$(ARTIFACTS)
        # Azure-specific test args
        - --provider=skeleton
        - --deployment=aksengine
        - --aksengine-agentpoolcount=2
        - --aksengine-admin-username=azureuser
        - --aksengine-creds=\$(AZURE_CREDENTIALS)
        - --aksengine-orchestratorRelease=${orchestrator_release}
        - --aksengine-mastervmsize=Standard_DS2_v2
        - --aksengine-agentvmsize=Standard_DS2_v2
        - --aksengine-deploy-custom-k8s
        - --aksengine-location=westus2
        - --aksengine-public-key=\$(AZURE_SSH_PUBLIC_KEY_FILE)
        - --aksengine-template-url=https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/master/test/e2e/manifest/in-tree.json
        - --aksengine-download-url=https://github.com/Azure/aks-engine/releases/download/nightly/aks-engine-nightly-linux-amd64.tar.gz
        # Specific test args
        - --test-azure-file-csi-driver
        securityContext:
          privileged: true
        env:
        - name: AZURE_STORAGE_DRIVER
          value: kubernetes.io/azure-file # In-tree Azure file storage class

periodics:
- interval: 24h
  name: aks-engine-conformance-${release/./-}
  decorate: true
  labels:
    preset-service-account: "true"
    preset-azure-cred: "true"
    preset-dind-enabled: "true"
  extra_refs:
  - org: kubernetes
    repo: kubernetes
    base_ref: ${branch}
    path_alias: k8s.io/kubernetes
  spec:
    containers:
    - image: gcr.io/k8s-testimages/kubekins-e2e:v20210412-176e4b6-${release}
      command:
      - runner.sh
      - kubetest
      args:
      # Generic e2e test args
      - --test
      - --up
      - --down
      - --build=quick
      - --dump=\$(ARTIFACTS)
      # Azure-specific test args
      - --provider=skeleton
      - --deployment=aksengine
      - --aksengine-agentpoolcount=2
      - --aksengine-admin-username=azureuser
      - --aksengine-creds=\$(AZURE_CREDENTIALS)
      - --aksengine-orchestratorRelease=${orchestrator_release}
      - --aksengine-mastervmsize=Standard_DS2_v2
      - --aksengine-agentvmsize=Standard_DS2_v2
      - --aksengine-deploy-custom-k8s
      - --aksengine-location=westus2
      - --aksengine-public-key=\$(AZURE_SSH_PUBLIC_KEY_FILE)
      - --aksengine-template-url=https://raw.githubusercontent.com/kubernetes-sigs/cloud-provider-azure/master/tests/k8s-azure/manifest/kubernetes.json
      - --aksengine-download-url=https://github.com/Azure/aks-engine/releases/download/nightly/aks-engine-nightly-linux-amd64.tar.gz
      # Specific test args
      - --test_args=--ginkgo.focus=\[Conformance\]
      - --ginkgo-parallel=1
      securityContext:
        privileged: true
  annotations:
    testgrid-dashboards: provider-azure-${release}-signal
    testgrid-tab-name: aks-engine-conformance
    testgrid-alert-email: kubernetes-provider-azure@googlegroups.com
    testgrid-num-columns-recent: '30'

- interval: 24h
  name: aks-engine-azure-disk-vmas-${release/./-}
  decorate: true
  labels:
    preset-service-account: "true"
    preset-azure-cred: "true"
    preset-dind-enabled: "true"
  extra_refs:
  - org: kubernetes
    repo: kubernetes
    base_ref: ${branch}
    path_alias: k8s.io/kubernetes
  - org: kubernetes-sigs
    repo: azuredisk-csi-driver
    base_ref: master
    path_alias: sigs.k8s.io/azuredisk-csi-driver
  spec:
    containers:
    - image: gcr.io/k8s-testimages/kubekins-e2e:v20210412-176e4b6-${release}
      command:
      - runner.sh
      - kubetest
      args:
      # Generic e2e test args
      - --test
      - --up
      - --down
      - --build=quick
      - --dump=\$(ARTIFACTS)
      # Azure-specific test args
      - --provider=skeleton
      - --deployment=aksengine
      - --aksengine-admin-username=azureuser
      - --aksengine-creds=\$(AZURE_CREDENTIALS)
      - --aksengine-orchestratorRelease=${orchestrator_release}
      - --aksengine-deploy-custom-k8s
      - --aksengine-location=westus2
      - --aksengine-public-key=\$(AZURE_SSH_PUBLIC_KEY_FILE)
      - --aksengine-template-url=https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/master/test/e2e/manifest/in-tree.json
      - --aksengine-download-url=https://github.com/Azure/aks-engine/releases/download/nightly/aks-engine-nightly-linux-amd64.tar.gz
      # Specific test args
      - --test-azure-disk-csi-driver
      securityContext:
        privileged: true
      env:
      - name: AZURE_STORAGE_DRIVER
        value: "kubernetes.io/azure-disk" # In-tree Azure disk storage class
  annotations:
    testgrid-dashboards: provider-azure-${release}-signal
    testgrid-tab-name: aks-engine-azure-disk-vmas
    testgrid-alert-email: kubernetes-provider-azure@googlegroups.com
    testgrid-num-columns-recent: '30'

- interval: 24h
  name: aks-engine-azure-disk-vmss-${release/./-}
  decorate: true
  labels:
    preset-service-account: "true"
    preset-azure-cred: "true"
    preset-dind-enabled: "true"
  extra_refs:
  - org: kubernetes
    repo: kubernetes
    base_ref: ${branch}
    path_alias: k8s.io/kubernetes
  - org: kubernetes-sigs
    repo: azuredisk-csi-driver
    base_ref: master
    path_alias: sigs.k8s.io/azuredisk-csi-driver
  spec:
    containers:
    - image: gcr.io/k8s-testimages/kubekins-e2e:v20210412-176e4b6-${release}
      command:
      - runner.sh
      - kubetest
      args:
      # Generic e2e test args
      - --test
      - --up
      - --down
      - --build=quick
      - --dump=\$(ARTIFACTS)
      # Azure-specific test args
      - --provider=skeleton
      - --deployment=aksengine
      - --aksengine-admin-username=azureuser
      - --aksengine-creds=\$(AZURE_CREDENTIALS)
      - --aksengine-orchestratorRelease=${orchestrator_release}
      - --aksengine-deploy-custom-k8s
      - --aksengine-location=westus2
      - --aksengine-public-key=\$(AZURE_SSH_PUBLIC_KEY_FILE)
      - --aksengine-template-url=https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/master/test/e2e/manifest/in-tree-vmss.json
      - --aksengine-download-url=https://github.com/Azure/aks-engine/releases/download/nightly/aks-engine-nightly-linux-amd64.tar.gz
      # Specific test args
      - --test-azure-disk-csi-driver
      securityContext:
        privileged: true
      env:
      - name: AZURE_STORAGE_DRIVER
        value: "kubernetes.io/azure-disk" # In-tree Azure disk storage class
      - name: ENABLE_TOPOLOGY
        value: "true"
  annotations:
    testgrid-dashboards: provider-azure-${release}-signal
    testgrid-tab-name: aks-engine-azure-disk-vmss
    testgrid-alert-email: kubernetes-provider-azure@googlegroups.com
    testgrid-num-columns-recent: '30'

- interval: 24h
  name: aks-engine-azure-file-${release/./-}
  decorate: true
  labels:
    preset-service-account: "true"
    preset-azure-cred: "true"
    preset-dind-enabled: "true"
  extra_refs:
  - org: kubernetes
    repo: kubernetes
    base_ref: ${branch}
    path_alias: k8s.io/kubernetes
  - org: kubernetes-sigs
    repo: azurefile-csi-driver
    base_ref: master
    path_alias: sigs.k8s.io/azurefile-csi-driver
  spec:
    containers:
    - image: gcr.io/k8s-testimages/kubekins-e2e:v20210412-176e4b6-${release}
      command:
      - runner.sh
      - kubetest
      args:
      # Generic e2e test args
      - --test
      - --up
      - --down
      - --build=quick
      - --dump=\$(ARTIFACTS)
      # Azure-specific test args
      - --provider=skeleton
      - --deployment=aksengine
      - --aksengine-agentpoolcount=2
      - --aksengine-admin-username=azureuser
      - --aksengine-creds=\$(AZURE_CREDENTIALS)
      - --aksengine-orchestratorRelease=${orchestrator_release}
      - --aksengine-mastervmsize=Standard_DS2_v2
      - --aksengine-agentvmsize=Standard_DS2_v2
      - --aksengine-deploy-custom-k8s
      - --aksengine-location=westus2
      - --aksengine-public-key=\$(AZURE_SSH_PUBLIC_KEY_FILE)
      - --aksengine-template-url=https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/master/test/e2e/manifest/in-tree.json
      - --aksengine-download-url=https://github.com/Azure/aks-engine/releases/download/nightly/aks-engine-nightly-linux-amd64.tar.gz
      # Specific test args
      - --test-azure-file-csi-driver
      securityContext:
        privileged: true
      env:
      - name: AZURE_STORAGE_DRIVER
        value: kubernetes.io/azure-file # In-tree Azure file storage class
  annotations:
    testgrid-dashboards: provider-azure-${release}-signal
    testgrid-tab-name: aks-engine-azure-file
    testgrid-alert-email: kubernetes-provider-azure@googlegroups.com
    testgrid-num-columns-recent: '30'

- interval: 24h
  name: capz-conformance-${release/./-}
  decorate: true
  decoration_config:
    timeout: 3h
  labels:
    preset-dind-enabled: "true"
    preset-kind-volume-mounts: "true"
    preset-azure-cred: "true"
  extra_refs:
  - org: kubernetes-sigs
    repo: cluster-api-provider-azure
    base_ref: master
    path_alias: sigs.k8s.io/cluster-api-provider-azure
  spec:
    containers:
    - image: gcr.io/k8s-testimages/kubekins-e2e:v20210412-176e4b6-master
      command:
      - runner.sh
      - ./scripts/ci-conformance.sh
      env:
      - name: E2E_ARGS
        value: "-kubetest.use-ci-artifacts"
      - name: KUBERNETES_VERSION
        value: "${kubernetes_version}"
      - name: CONFORMANCE_WORKER_MACHINE_COUNT
        value: "2"
      securityContext:
        privileged: true
      resources:
        requests:
          cpu: 1
          memory: "4Gi"
  annotations:
    testgrid-dashboards: provider-azure-${release}-signal
    testgrid-tab-name: capz-conformance
    testgrid-alert-email: kubernetes-provider-azure@googlegroups.com
    testgrid-num-columns-recent: '30'

- interval: 24h
  name: capz-azure-file-${release/./-}
  decorate: true
  decoration_config:
    timeout: 3h
  labels:
    preset-dind-enabled: "true"
    preset-kind-volume-mounts: "true"
    preset-azure-cred: "true"
  extra_refs:
  - org: kubernetes-sigs
    repo: cluster-api-provider-azure
    base_ref: master
    path_alias: sigs.k8s.io/cluster-api-provider-azure
  - org: kubernetes-sigs
    repo: azurefile-csi-driver
    base_ref: master
    path_alias: sigs.k8s.io/azurefile-csi-driver
  - org: kubernetes
    repo: kubernetes
    base_ref: ${branch}
    path_alias: k8s.io/kubernetes
  spec:
    containers:
    - image: gcr.io/k8s-testimages/kubekins-e2e:v20210412-176e4b6-master
      command:
      - runner.sh
      - ./scripts/ci-entrypoint.sh
      args:
      - bash
      - -c
      - >-
        kubectl apply -f templates/addons/azurefile-role.yaml &&
        cd \${GOPATH}/src/sigs.k8s.io/azurefile-csi-driver &&
        make e2e-test
      env:
      - name: USE_CI_ARTIFACTS
        value: "true"
      - name: AZURE_STORAGE_DRIVER
        value: kubernetes.io/azure-file # In-tree Azure file storage class
      securityContext:
        privileged: true
      resources:
        requests:
          cpu: 1
          memory: "4Gi"
  annotations:
    testgrid-dashboards: provider-azure-${release}-signal
    testgrid-tab-name: capz-azure-file
    testgrid-alert-email: kubernetes-provider-azure@googlegroups.com
    testgrid-num-columns-recent: '30'

- interval: 24h
  name: capz-azure-file-machinepool-${release/./-}
  decorate: true
  decoration_config:
    timeout: 3h
  labels:
    preset-dind-enabled: "true"
    preset-kind-volume-mounts: "true"
    preset-azure-cred: "true"
  extra_refs:
  - org: kubernetes-sigs
    repo: cluster-api-provider-azure
    base_ref: master
    path_alias: sigs.k8s.io/cluster-api-provider-azure
  - org: kubernetes-sigs
    repo: azurefile-csi-driver
    base_ref: master
    path_alias: sigs.k8s.io/azurefile-csi-driver
  - org: kubernetes
    repo: kubernetes
    base_ref: ${branch}
    path_alias: k8s.io/kubernetes
  spec:
    containers:
    - image: gcr.io/k8s-testimages/kubekins-e2e:v20210412-176e4b6-master
      command:
      - runner.sh
      - ./scripts/ci-entrypoint.sh
      args:
      - bash
      - -c
      - >-
        kubectl apply -f templates/addons/azurefile-role.yaml &&
        cd \${GOPATH}/src/sigs.k8s.io/azurefile-csi-driver &&
        make e2e-test
      env:
      - name: USE_CI_ARTIFACTS
        value: "true"
      - name: EXP_MACHINE_POOL
        value: "true"
      - name: AZURE_STORAGE_DRIVER
        value: kubernetes.io/azure-file # In-tree Azure file storage class
      securityContext:
        privileged: true
      resources:
        requests:
          cpu: 1
          memory: "4Gi"
  annotations:
    testgrid-dashboards: provider-azure-${release}-signal
    testgrid-tab-name: capz-azure-file-machinepool
    testgrid-alert-email: kubernetes-provider-azure@googlegroups.com
    testgrid-num-columns-recent: '30'

- interval: 24h
  name: capz-azure-disk-${release/./-}
  decorate: true
  decoration_config:
    timeout: 3h
  labels:
    preset-dind-enabled: "true"
    preset-kind-volume-mounts: "true"
    preset-azure-cred: "true"
  extra_refs:
  - org: kubernetes-sigs
    repo: cluster-api-provider-azure
    base_ref: master
    path_alias: sigs.k8s.io/cluster-api-provider-azure
  - org: kubernetes-sigs
    repo: azuredisk-csi-driver
    base_ref: master
    path_alias: sigs.k8s.io/azuredisk-csi-driver
  - org: kubernetes
    repo: kubernetes
    base_ref: ${branch}
    path_alias: k8s.io/kubernetes
  spec:
    containers:
    - image: gcr.io/k8s-testimages/kubekins-e2e:v20210412-176e4b6-master
      command:
      - runner.sh
      - ./scripts/ci-entrypoint.sh
      args:
      - bash
      - -c
      - >-
        cd \${GOPATH}/src/sigs.k8s.io/azuredisk-csi-driver &&
        make e2e-test
      env:
      - name: USE_CI_ARTIFACTS
        value: "true"
      - name: AZURE_STORAGE_DRIVER
        value: kubernetes.io/azure-disk # In-tree Azure disk storage class
      securityContext:
        privileged: true
      resources:
        requests:
          cpu: 1
          memory: "4Gi"
  annotations:
    testgrid-dashboards: provider-azure-${release}-signal
    testgrid-tab-name: capz-azure-disk
    testgrid-alert-email: kubernetes-provider-azure@googlegroups.com
    testgrid-num-columns-recent: '30'

- interval: 24h
  name: capz-azure-disk-machinepool-${release/./-}
  decorate: true
  decoration_config:
    timeout: 3h
  labels:
    preset-dind-enabled: "true"
    preset-kind-volume-mounts: "true"
    preset-azure-cred: "true"
  extra_refs:
  - org: kubernetes-sigs
    repo: cluster-api-provider-azure
    base_ref: master
    path_alias: sigs.k8s.io/cluster-api-provider-azure
  - org: kubernetes-sigs
    repo: azuredisk-csi-driver
    base_ref: master
    path_alias: sigs.k8s.io/azuredisk-csi-driver
  - org: kubernetes
    repo: kubernetes
    base_ref: ${branch}
    path_alias: k8s.io/kubernetes
  spec:
    containers:
    - image: gcr.io/k8s-testimages/kubekins-e2e:v20210412-176e4b6-master
      command:
      - runner.sh
      - ./scripts/ci-entrypoint.sh
      args:
      - bash
      - -c
      - >-
        cd \${GOPATH}/src/sigs.k8s.io/azuredisk-csi-driver &&
        make e2e-test
      env:
      - name: USE_CI_ARTIFACTS
        value: "true"
      - name: EXP_MACHINE_POOL
        value: "true"
      - name: AZURE_STORAGE_DRIVER
        value: kubernetes.io/azure-disk # In-tree Azure disk storage class
      securityContext:
        privileged: true
      resources:
        requests:
          cpu: 1
          memory: "4Gi"
  annotations:
    testgrid-dashboards: provider-azure-${release}-signal
    testgrid-tab-name: capz-azure-disk-machinepool
    testgrid-alert-email: kubernetes-provider-azure@googlegroups.com
    testgrid-num-columns-recent: '30'
EOF
done
