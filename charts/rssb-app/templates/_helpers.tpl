{{/* Object name: the Helm release name, which Argo CD sets to the app folder name. */}}
{{- define "app.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Labels on every object (not on pods: a chart upgrade must not restart them). */}}
{{- define "app.labels" -}}
{{ include "app.selectorLabels" . }}
{{- with .Values.partOf }}
app.kubernetes.io/part-of: {{ . }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{/* Labels used to find this app's pods. Never change them: selectors are immutable. */}}
{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
{{- end -}}

{{/*
"repository@digest" for one image, looked up in .Values.images (the list CI
updates). Usage: include "app.image" (list . .Values.image.repository)
*/}}
{{- define "app.image" -}}
{{- $root := index . 0 -}}
{{- $repo := required "image repository is required" (index . 1) -}}
{{- $digest := "" -}}
{{- range $root.Values.images -}}
{{- if eq .name $repo }}{{ $digest = .digest }}{{ end -}}
{{- end -}}
{{- if not (hasPrefix "sha256:" $digest) -}}
{{- fail (printf "%s has no image yet: CI writes its digest into images after the first build on develop" $repo) -}}
{{- end -}}
{{- printf "%s@%s" $repo $digest -}}
{{- end -}}

{{/* Restricted pod security (the namespaces enforce the "restricted" standard). */}}
{{- define "app.podSecurityContext" -}}
runAsNonRoot: true
runAsUser: 1000
runAsGroup: 1000
seccompProfile: { type: RuntimeDefault }
{{- end -}}

{{- define "app.containerSecurityContext" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
capabilities: { drop: ["ALL"] }
{{- end -}}
