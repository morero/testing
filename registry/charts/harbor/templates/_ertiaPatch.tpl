{{/*
Harbor admin password secret name
*/}}
{{- define "harbor.ertia.adminSecretName" -}}
{{- printf "%s" "ertia-harbor-admin"}}
{{- end -}}

{{/*
Looks if there's an existing Harbor admin secret and reuse its password. If not it generates
new password and use it.
*/}}
{{- define "harbor.ertia.adminPassword" -}}
{{- $secret := (lookup "v1" "Secret" (.Release.Namespace) (include "harbor.ertia.adminSecretName" .) ) -}}
  {{- if $secret -}}
    {{-  index $secret "data" "password" | b64dec -}}
  {{- else -}}
    {{- fail "could not find secret: ertia-harbor-admin" -}}
  {{- end -}}
{{- end -}}

{{/*
Harbor secretKey secret name
*/}}
{{- define "harbor.ertia.secretKeyName" -}}
{{- printf "%s" "ertia-harbor-secret-key"}}
{{- end -}}

{{/*
Looks if there's an existing Harbor secretKey secret and reuse its secret. If not it generates
new secretKey and use it. This key is used for encryption and must be a string of 16 chars.
*/}}
{{- define "harbor.ertia.secretKey" -}}
{{- $secret := (lookup "v1" "Secret" (.Release.Namespace) (include "harbor.ertia.secretKeyName" .) ) -}}
  {{- if $secret -}}
    {{-  index $secret "data" "key" | b64dec -}}
  {{- else -}}
    {{- fail "could not find secret: ertia-harbor-secret-key" -}}
  {{- end -}}
{{- end -}}

{{/*
Harbor DB password secret name
*/}}
{{- define "harbor.ertia.dbSecretName" -}}
{{- printf "%s" "ertia-harbor-db"}}
{{- end -}}

{{/*
Looks if there's an existing Harbor DB secret and reuse its password. If not it generates
new password and use it.
*/}}
{{- define "harbor.ertia.dbPassword" -}}
{{- $secret := (lookup "v1" "Secret" (.Release.Namespace) (include "harbor.ertia.dbSecretName" .) ) -}}
  {{- if $secret -}}
    {{-  index $secret "data" "password" | b64dec  -}}
  {{- else -}}
    {{- fail "could not find secret: ertia-harbor-db" -}}
  {{- end -}}
{{- end -}}

{{/*
Harbor registry credential password secret name
*/}}
{{- define "harbor.ertia.registrySecretName" -}}
{{- printf "%s" "ertia-harbor-registry"}}
{{- end -}}

{{/*
Looks if there's an existing Harbor registry credential secret and reuse its password. If not it generates
new password and use it.
*/}}
{{- define "harbor.ertia.registryPassword" -}}
{{- $secret := (lookup "v1" "Secret" (.Release.Namespace) (include "harbor.ertia.registrySecretName" .) ) -}}
  {{- if $secret -}}
    {{-  index $secret "data" "password" | b64dec -}}
  {{- else -}}
    {{- fail "could not find secret: ertia-harbor-registry" -}}
  {{- end -}}
{{- end -}}
