#!/bin/sh
helm install -n registry registry-main --debug --post-renderer=./kustomize helm 
