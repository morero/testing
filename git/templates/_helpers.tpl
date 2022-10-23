{{/*
Expand the name of the chart.
*/}}
{{- define "git.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "git.fullname" -}}
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
{{- define "git.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "git.labels" -}}
helm.sh/chart: {{ include "git.chart" . }}
{{ include "git.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "git.selectorLabels" -}}
app.kubernetes.io/name: {{ include "git.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "git.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "git.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "git.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{/*
Looks if there's an existing admin secret and reuse its password. If not it generates
new password and use it.
*/}}
{{- define "gitea.admin-password" -}}
{{- $secret := (lookup "v1" "Secret" (include "git.namespace" .) "gitea-admin-secret") -}}
  {{- if $secret -}}
    {{- index $secret "data" "password" -}}
  {{- else -}}
    {{- (randAlphaNum 40) | b64enc | quote -}}
  {{- end -}}
{{- end -}}

{{/*
Gitea admin username
*/}}
{{- define "gitea.admin-username" -}}
{{- printf "gitea_admin" | b64enc | quote -}}
{{- end -}}

{{/*
Gitea tekton username
*/}}
{{- define "gitea.tekton-username" -}}
{{- printf "tekton" | b64enc | quote -}}
{{- end -}}

{{/*
Looks if there's an existing tekton secret and reuse its password. If not it generates
new password and use it.
*/}}
{{- define "gitea.tekton-password" -}}
{{- $secret := (lookup "v1" "Secret" (include "git.namespace" .) "gitea-tekton-secret") -}}
  {{- if $secret -}}
    {{- index $secret "data" "password" -}}
  {{- else -}}
    {{- (randAlphaNum 40) | b64enc | quote -}}
  {{- end -}}
{{- end -}}

{{/*
Looks if there's an existing admin secret and reuse its password. If not it generates
new password and use it.
*/}}
{{- define "gitea.oauth.secret" -}}
{{- $secret := (lookup "v1" "Secret" (include "git.namespace" .) "zitadel-oauth") -}}
  {{- if $secret -}}
    {{- index $secret "data" "secret" -}}
  {{- else -}}
    {{- (randAlphaNum 40) | b64enc | quote -}}
  {{- end -}}
{{- end -}}