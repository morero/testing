{{/*
Expand the name of the chart.
*/}}
{{- define "arangodb.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "arangodb.fullname" -}}
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
{{- define "arangodb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "arangodb.labels" -}}
helm.sh/chart: {{ include "arangodb.chart" . }}
{{ include "arangodb.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "arangodb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "arangodb.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "arangodb.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "arangodb.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Arango operator dashboard user
*/}}
{{- define "arangodb.operator-dashboard-user" -}}
{{- printf "%s" "dashboard" | b64enc -}}
{{- end -}}

{{/*
Arango operator dashboard user password
*/}}
{{- define "arangodb.operator-dashboard-passsword" -}}
{{- $operatorsecret := (lookup "v1" "Secret" .Release.Namespace .Values.operator.dashboard.secretName) -}}
  {{- if $operatorsecret -}}
    {{-  index $operatorsecret "data" "password" -}}
  {{- else -}}
    {{- (randAlphaNum 40) | b64enc -}}
  {{- end -}}
{{- end -}}

{{/*
ArangoDB prod root user
*/}}
{{- define "arangodb.prod-root-user" -}}
{{- printf "%s" "root" | b64enc -}}
{{- end -}}

{{/*
ArangoDB prod root password
*/}}
{{- define "arangodb.prod-root-passsword" -}}
{{- $prodrootsecret := (lookup "v1" "Secret" .Release.Namespace .Values.arangodb.prod.rootSecretName) -}}
  {{- if $prodrootsecret -}}
    {{-  index $prodrootsecret "data" "password" -}}
  {{- else -}}
    {{- (randAlphaNum 40) | b64enc -}}
  {{- end -}}
{{- end -}}
