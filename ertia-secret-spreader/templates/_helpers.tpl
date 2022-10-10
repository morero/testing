{{/*
Expand the name of the chart.
*/}}
{{- define "ertia-secret-spreader.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ertia-secret-spreader.fullname" -}}
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
{{- define "ertia-secret-spreader.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ertia-secret-spreader.labels" -}}
helm.sh/chart: {{ include "ertia-secret-spreader.chart" . }}
{{ include "ertia-secret-spreader.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ertia-secret-spreader.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ertia-secret-spreader.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ertia-secret-spreader.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ertia-secret-spreader.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get Ertia domain
*/}}
{{- define "ertia.domain" -}}
{{- $ertiadomain := (lookup "v1" "Secret" .Release.Namespace "ertia-domain") -}}
  {{- if $ertiadomain -}}
    {{-  index $ertiadomain "data" "domain" | b64dec -}}
  {{- else -}}
    {{- "could.not.find.domain" -}}
  {{- end -}}
{{- end -}}

{{/*
Gitea Hostname
*/}}
{{- define "gitea.hostname" -}}
{{ .Values.gitea.hostName }}
{{- end -}}

{{/*
Gitea Tekton user
*/}}
{{- define "gitea.tekton-user" -}}
{{- printf "%s" "tekton" -}}
{{- end -}}

{{/*
Get Tekton gitea token
*/}}
{{- define "gitea.tekton-token" -}}
{{- $tektontoken := (lookup "v1" "Secret" .Release.Namespace "tekton-gitea-token") -}}
  {{- if $tektontoken -}}
    {{-  index $tektontoken "data" "token" | b64dec -}}
  {{- else -}}
    {{- "could_not_get_tekton_gitea_token" -}}
  {{- end -}}
{{- end -}}

{{/*
Gitea config for Tekton user
*/}}
{{- define "gitea.tekton-user-gitconfig" -}}
[credential "http://{{- include "gitea.hostname" . -}}"]
  helper = store
{{- end -}}

{{/*
Gitea git-credentials for Tekton user
*/}}
{{- define "gitea.tekton-user-git-credentials" -}}
http://{{- include "gitea.tekton-user" . -}}:{{- include "gitea.tekton-token" . -}}@{{- include "gitea.hostname" . -}}
{{- end -}}

{{/*
Harbor Tekton robot user
*/}}
{{- define "harbor.tekton-robot-user" -}}
{{- printf "%s" "robot$tekton" -}}
{{- end -}}

{{/*
Get Harbor Tekton robot token
*/}}
{{- define "harbor.tekton-robot-token" -}}
{{- $harborsecret := (lookup "v1" "Secret" "registry" "ertia-harbor-tekton-robot-token") -}}
  {{- if $harborsecret -}}
    {{-  index $harborsecret "data" "token" | b64dec -}}
  {{- else -}}
    {{- "could_not_get_tekton_harbor_token" -}}
  {{- end -}}
{{- end -}}

{{/*
Docker config.json for Harbor Tekton robot user
*/}}
{{- define "harbor.tekton-robot-docker-config" -}}
{
  "auths": {
    "registry-harbor-core.registry.svc.cluster.local": {
      "username": {{- include "harbor.tekton-robot-user" . | quote -}},
      "password": {{- include "harbor.tekton-robot-token" . | quote -}},
      "email": "tekton@ertia.io",
      "auth": {{- printf "%s:%s" (include "harbor.tekton-robot-user" .) (include "harbor.tekton-robot-token" .) | b64enc | quote }}
    },
    "registry.{{- include "ertia.domain" . -}}": {
      "username": {{- include "harbor.tekton-robot-user" . | quote -}},
      "password": {{- include "harbor.tekton-robot-token" . | quote -}},
      "email": "tekton@ertia.io",
      "auth": {{- printf "%s:%s" (include "harbor.tekton-robot-user" .) (include "harbor.tekton-robot-token" .) | b64enc | quote }}
    }
  }
}
{{- end -}}
