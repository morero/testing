{{/*
Expand the name of the chart.
*/}}
{{- define "registry-secret.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "registry-secret.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "registry-secret.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "registry-secret.labels" -}}
helm.sh/chart: {{ include "registry-secret.chart" . }}
{{ include "registry-secret.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "registry-secret.selectorLabels" -}}
app.kubernetes.io/name: {{ include "registry-secret.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "registry-secret.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "registry-secret.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

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
    {{- (randAlphaNum 48) -}}
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
    {{- (randAlphaNum 16) -}}
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
    {{- (randAlphaNum 48) -}}
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
    {{- (randAlphaNum 48) -}}
  {{- end -}}
{{- end -}}

{{/*
Harbor tekton robot token secret name
*/}}
{{- define "harbor.ertia.tektonSecretName" -}}
{{- printf "%s" "ertia-harbor-tekton-robot-token"}}
{{- end -}}

{{/*
Looks if there's an existing Harbor Tekton robot secret and reuse its token. If not, it generates
new token and use it.
*/}}
{{- define "harbor.ertia.tektonToken" -}}
{{- $secret := (lookup "v1" "Secret" (.Release.Namespace) (include "harbor.ertia.tektonSecretName" .) ) -}}
  {{- if $secret -}}
    {{-  index $secret "data" "token" | b64dec -}}
  {{- else -}}
    {{- (randAlphaNum 32) -}}
  {{- end -}}
{{- end -}}
