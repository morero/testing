//usr/bin/env go run "$0" "$@"; exit
package main

import (
    "fmt"
    "os"
)

const LOCAL_DOMAIN = "local.ertia.cloud"

func main() {
    domain := os.Getenv("DOMAIN")

    if(domain ==""){
        return
    }

    if(domain == LOCAL_DOMAIN){
        return
    }


lookup := nslookup ${DOMAIN}

domainOk := false

for cfg.nodes {
  if(string.Contains(lookup, node.ip)){
    domainOk = true
  }
}



kubectl get ingress -l cert-upgrade=true



kubectl get -A ingress -l app.kubernetes.io/name=gitea

kubectl get ingress -Ao jsonpath='{range .items[*]}{@.metadata.name}{" "}{@..spec.tls..hosts}{"\n"}{end}'
kubectl get ingress -Ao jsonpath='{range .items[*]}{@.metadata.namespace}{"#"}{@.metadata.name}{"#"}{@..spec.tls..hosts}{"\n"}{end}'

kubectl patch deployment simple --type=json -p='[{"op": "add", "path": "/spec/template/metadata/labels/this", "value": "that"}]'

    fmt.Printf("Hello World\n")
}
