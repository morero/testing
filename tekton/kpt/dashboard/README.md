# dashboard

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] dashboard`
Details: https://googlecontainertools.github.io/kpt/reference/pkg/get/

### View package content
`kpt cfg tree dashboard`
Details: https://googlecontainertools.github.io/kpt/reference/cfg/tree/

### List setters
`kpt cfg list-setters dashboard`
Details: https://googlecontainertools.github.io/kpt/reference/cfg/list-setters/

### Set a value
`kpt cfg set dashboard NAME VALUE`
Details: https://googlecontainertools.github.io/kpt/reference/cfg/set/

### Apply the package
```
kpt live init dashboard
kpt live apply dashboard --reconcile-timeout=2m --output=table
```
Details: https://googlecontainertools.github.io/kpt/reference/live/
