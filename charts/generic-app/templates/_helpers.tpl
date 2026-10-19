{{/* Object name: the release name unless overridden. */}}
{{- define "app.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Labels on every object. */}}
{{- define "app.labels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{/* Labels used to find this app's pods (must never change after install). */}}
{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
{{- end -}}

{{/* Labels that grant network access (see cluster/network-policies.yaml). */}}
{{- define "app.accessLabels" -}}
{{- if .Values.database.access }}
rssb.rw/database-access: "true"
{{- end }}
{{- end -}}

{{/* Restricted pod security context (namespace enforces "restricted"). */}}
{{- define "app.podSecurityContext" -}}
runAsNonRoot: true
runAsUser: 1000
runAsGroup: 1000
seccompProfile:
  type: RuntimeDefault
{{- end -}}

{{- define "app.containerSecurityContext" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
capabilities:
  drop: ["ALL"]
{{- end -}}

{{/* env vars from the ConfigMap and the Secret. */}}
{{- define "app.envFrom" -}}
{{- if .Values.env }}
- configMapRef:
    name: {{ include "app.name" . }}
{{- end }}
{{- if .Values.existingSecret }}
- secretRef:
    name: {{ .Values.existingSecret }}
{{- end }}
{{- end -}}
