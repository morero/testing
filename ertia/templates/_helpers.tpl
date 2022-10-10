{{/* vim: set filetype=mustache: */}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ertia.fullname" -}}
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
Expand the name of the chart.
*/}}
{{- define "ertia.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Allow the release namespace to be overridden
*/}}
{{- define "ertia.namespace" -}}
  {{- if .Values.namespace -}}
    {{- .Values.namespace -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ertia.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ertia.labels" -}}
helm.sh/chart: {{ include "ertia.chart" . }}
{{ include "ertia.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
 */}}
{{- define "ertia.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ertia.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Grafana dashboard label
*/}}
{{- define "grafana.dashboard" -}}
{{ $.Values.grafana.dashboard.label | default "grafana_dashboard" }}: "1"
{{- end -}}

{{/*
Grafana folder annotation
*/}}
{{- define "grafana.folder" -}}
{{ .Values.grafana.dashboard.folderLabel | default "grafana_folder" }}: "/tmp/dashboards/{{ .Release.Name }}"
{{- end -}}

{{/*
Looks if there's an existing secret and reuse its password. If not it generates
new password and use it.
*/}}
{{- define "ertia.password" -}}
{{- $secret := (lookup "v1" "Secret" (include "ertia.namespace" .) (include "ertia.name" .) ) -}}
  {{- if $secret -}}
    {{-  index $secret "data" "password" -}}
  {{- else -}}
    {{- (randAlphaNum 40) | b64enc | quote -}}
  {{- end -}}
{{- end -}}

{{/*
Get gitea admin password
*/}}
{{- define "gitea.admin-password" -}}
{{- $giteasecret := (lookup "v1" "Secret" "git" "gitea-admin-secret") -}}
  {{- if $giteasecret -}}
    {{-  index $giteasecret "data" "password" | b64dec | quote -}}
  {{- end -}}
{{- end -}}

{{/*
Get gitea tekton password
*/}}
{{- define "gitea.tekton-password" -}}
{{- $giteasecret := (lookup "v1" "Secret" "git" "gitea-tekton-secret") -}}
  {{- if $giteasecret -}}
    {{-  index $giteasecret "data" "password" | b64dec | quote -}}
  {{- end -}}
{{- end -}}

{{/*
Get Harbor admin password
*/}}
{{- define "harbor.admin-password" -}}
{{- $harborsecret := (lookup "v1" "Secret" "registry" "ertia-harbor-admin") -}}
  {{- if $harborsecret -}}
    {{-  index $harborsecret "data" "password" | b64dec -}}
  {{- end -}}
{{- end -}}

{{/*
Get Harbor Tekton robot token
*/}}
{{- define "harbor.tekton-robot-token" -}}
{{- $harborsecret := (lookup "v1" "Secret" "registry" "ertia-harbor-tekton-robot-token") -}}
  {{- if $harborsecret -}}
    {{-  index $harborsecret "data" "token" | b64dec -}}
  {{- end -}}
{{- end -}}
