# triggers

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] triggers`
Details: https://googlecontainertools.github.io/kpt/reference/pkg/get/

### View package content
`kpt cfg tree triggers`
Details: https://googlecontainertools.github.io/kpt/reference/cfg/tree/

### List setters
`kpt cfg list-setters triggers`
Details: https://googlecontainertools.github.io/kpt/reference/cfg/list-setters/

### Set a value
`kpt cfg set triggers NAME VALUE`
Details: https://googlecontainertools.github.io/kpt/reference/cfg/set/

### Apply the package
```
kpt live init triggers
kpt live apply triggers --reconcile-timeout=2m --output=table
```
Details: https://googlecontainertools.github.io/kpt/reference/live/
