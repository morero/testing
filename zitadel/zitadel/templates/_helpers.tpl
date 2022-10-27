
{{- define "zitadel.postgres-username" -}}
{{- $secret := (lookup "v1" "Secret" "stolon" "postgres-zitadel") -}}
  {{- if $secret -}}
    {{- index $secret "data" "username" -}}
  {{- else -}}
    {{- (randAlphaNum 40) | b64enc | quote -}}
  {{- end -}}
{{- end -}}

{{- define "zitadel.postgres-password" -}}
{{- $secret := (lookup "v1" "Secret" "stolon" "postgres-zitadel") -}}
  {{- if $secret -}}
    {{- index $secret "data" "password" -}}
  {{- else -}}
    {{- (randAlphaNum 40) | b64enc | quote -}}
  {{- end -}}
{{- end -}}

{{- define "zitadel.postgres-database" -}}
{{- $secret := (lookup "v1" "Secret" "stolon" "postgres-zitadel") -}}
  {{- if $secret -}}
    {{- index $secret "data" "database" -}}
  {{- else -}}
    {{- (randAlphaNum 40) | b64enc | quote -}}
  {{- end -}}
{{- end -}}
