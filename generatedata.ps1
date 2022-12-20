# Generate lots of fake data quickly
$headers = @{'Accept' = 'application/json'}
$progressPreference = 'silentlyContinue'
$params = Get-ComputerInfo
while ($true) {
    $random = get-random
    invoke-webrequest -usebasicparsing -Headers $headers -method PUT http://localhost:5984/data/$random -body ($params|convertto-json) -contentType "application/json"
}