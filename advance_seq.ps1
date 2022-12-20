function Update-SequenceID([int]$low_seq, [int]$high_seq, [string]$sourceCN, [string]$destCN, [string]$sourceDBName, [string]$destDBName) {
    # Add Auth Headers Here
    $headers = @{"Content-Type"="application/json"}

    if (($high_seq - $low_seq) -lt 2) {
        return $low_seq
    } else {

        $test_id = [math]::Floor(($low_seq + $high_seq) / 2)
        $res = Invoke-WebRequest -UseBasicParsing "http://$sourceCN`:5984/$sourceDBName/_changes?limit=1&since=$test_id" -headers $headers
        $resjson = convertfrom-json $res.content

        $id = $resjson.results.id
        $rev= $resjson.results.changes.rev

        try {
        $res2 = Invoke-WebRequest -UseBasicParsing -ea SilentlyContinue "http://$destCN`:5984/$destDBname/$id`?rev=$rev" -headers $headers
        } catch {
           if ($_.Exception.Response.StatusCode -eq "NotFound") {
            write-host "doc doesn't exists"
            return Update-SequenceID $low_seq $test_id $sourceCN $destCN $sourceDBName $destDBName
           } else {
                write-host $_.Exception.Response.StatusCode
                write-host "Exiting due to unexpected status code, check auth headers and error above"
                return "Error Finding Result"
           }
        }

        $res2 = ConvertFrom-Json $res2.content
        if ($rev -eq $res2._rev) {
            write-host "doc exists"
            return Update-SequenceID $test_id $high_seq $sourceCN $destCN $sourceDBName $destDBName
        } else {
            return Update-SequenceID $low_seq $test_id $sourceCN $destCN $sourceDBName $destDBName
        }

    }



}

#Set values here, this can be automated by grabbing highest source_seq ID

# Internal DB Name
$sourceDBName="data"
# Client DB Name
$destDBName="data2"
# Internal DNS Name
$sourceCN = "localhost"
# Client DB Name
$destCN = "localhost"

# Automate by getting highest source seq from sourceCN:5984/DBName -> update_seq field
$high_seq = 141431
# Automate by getting latest replication checkpoint from destCN
$low_seq = 1

$targetSeqID = Update-SequenceID $low_seq $high_seq $sourceCN $destCN $sourceDBName $destDBName
write-host $targetSeqID
