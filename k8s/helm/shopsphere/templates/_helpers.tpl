{{- define "shopsphere.labels" -}}
app.kubernetes.io/part-of: shopsphere
app.kubernetes.io/managed-by: {{ .Release.Service }}
environment: {{ .Values.global.env }}
{{- end -}}
