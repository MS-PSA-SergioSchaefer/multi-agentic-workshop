[CmdletBinding()]
param(
    [string]$ProjectEndpoint = 'https://XXXXXXX-xxxxx-resource.services.ai.azure.com/api/projects/<Project-Name>',
    [string]$AgentName = 'AndersAgent',
    [string]$AgentVersion = '2',
    [string]$ResultsPath
)

$ErrorActionPreference = 'Stop'
Get-Command az -ErrorAction Stop | Out-Null
$token = az account get-access-token --resource https://ai.azure.com --query accessToken -o tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($token)) {
    throw 'Unable to obtain a Foundry token. Run az login for the project tenant.'
}

$headers = @{ Authorization = "Bearer $token" }
$expectedSource = 'https://XXXXXXXXXXXX.blob.core.windows.net/bikes/0000109727-warranty-intl-en.pdf'
$cases = @(
    @{
        Name = 'English warranty retrieval'
        Prompt = 'Use the connected knowledge base: What proof of original retail purchase must a subsequent owner provide under the Specialized limited warranty? Cite the source.'
        ExpectedText = '(?i)proof|purchase'
    },
    @{
        Name = 'Spanish warranty retrieval'
        Prompt = 'Responde en espanol usando la base de conocimiento conectada: Si soy el segundo propietario de una bicicleta Specialized, que comprobante de compra original necesito para la garantia? Cita el documento.'
        ExpectedText = '(?i)comprobante|compra'
    }
)

$results = foreach ($case in $cases) {
    $reference = @{ type = 'agent_reference'; name = $AgentName }
    if ($AgentVersion) {
        $reference.version = $AgentVersion
    }
    $body = @{
        agent_reference = $reference
        input = $case.Prompt
        tool_choice = 'required'
    } | ConvertTo-Json -Depth 8

    try {
        $response = Invoke-RestMethod -Method Post `
            -Uri "$($ProjectEndpoint.TrimEnd('/'))/openai/responses?api-version=2025-11-15-preview" `
            -Headers $headers -ContentType 'application/json' -Body $body -TimeoutSec 180
    }
    catch {
        throw "Test '$($case.Name)' failed: $($_.Exception.Message) $($_.ErrorDetails.Message)"
    }

    if ($response.status -ne 'completed' -or $response.error) {
        throw "Test '$($case.Name)' returned status '$($response.status)': $($response.error | ConvertTo-Json -Compress)"
    }
    $calls = @($response.output | Where-Object { $_.type -eq 'mcp_call' })
    $retrievals = @($calls | Where-Object { $_.name -eq 'knowledge_base_retrieve' })
    if ($retrievals.Count -eq 0 -or @($calls | Where-Object { $_.error }).Count -gt 0) {
        throw "Test '$($case.Name)' did not complete knowledge-base retrieval successfully."
    }
    $content = @(
        $response.output |
            Where-Object { $_.type -eq 'message' } |
            ForEach-Object { $_.content } |
            Where-Object { $_.type -eq 'output_text' }
    )
    $answer = ($content | ForEach-Object { $_.text }) -join "`n"
    $citations = @(
        $content | ForEach-Object { $_.annotations } |
            Where-Object { $_.type -eq 'url_citation' }
    )
    if ([string]::IsNullOrWhiteSpace($answer) -or $answer -notmatch $case.ExpectedText -or $answer -notmatch '(?i)original') {
        throw "Test '$($case.Name)' did not return the expected purchase-proof answer: $answer"
    }
    if (@($citations | Where-Object { $_.url -eq $expectedSource }).Count -eq 0) {
        throw "Test '$($case.Name)' did not cite the expected warranty PDF: $answer"
    }

    [pscustomobject]@{
        test = $case.Name
        passed = $true
        testedAtUtc = [DateTime]::UtcNow.ToString('o')
        projectEndpoint = $ProjectEndpoint
        agentName = $AgentName
        agentVersion = $response.agent_reference.version
        responseId = $response.id
        status = $response.status
        retrievalCalls = $retrievals.Count
        citationUrls = @($citations.url | Select-Object -Unique)
        answer = $answer
    }
}

if ($ResultsPath) {
    $results | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ResultsPath -Encoding utf8
}
$results | Select-Object test, passed, agentVersion, responseId, retrievalCalls
