#!/bin/sh
helm install -n tekton-pipelines tekton-main --debug --post-renderer=./kustomize helm 
