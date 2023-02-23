# Percona (Postgres HA) database
This will insall percona ppostgres HA cluster

## Fix

Problem: CRD is too big for kubectl apply command (we could use create, but we need update to work).
Fix: make annotaions smaller is to strip descriptions in file.
Use following command to replace all keys description with new value

``` 
yq e '(..|select(has("description")).["description"]) |= "some description"'  crd_with_descriptions/bundle.yaml > crd/bundle.yaml
```