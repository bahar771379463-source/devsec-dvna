<html>
<head>
<title>Trivy Report</title>
<style>
body { font-family: Arial; background:#f5f5f5; padding:20px; }
table { border-collapse: collapse; width:100%; }
th, td { border:1px solid #ccc; padding:8px; }
th { background:#333; color:white; }
</style>
</head>
<body>
<h1>Trivy Security Report</h1>
{{ range .Results }}
<h2>{{ .Target }}</h2>
<table>
<tr><th>ID</th><th>Package</th><th>Severity</th><th>Description</th></tr>
{{ range .Vulnerabilities }}
<tr>
<td>{{ .VulnerabilityID }}</td>
<td>{{ .PkgName }}</td>
<td>{{ .Severity }}</td>
<td>{{ .Title }}</td>
</tr>
{{ end }}
</table>
{{ end }}
</body>
</html>
