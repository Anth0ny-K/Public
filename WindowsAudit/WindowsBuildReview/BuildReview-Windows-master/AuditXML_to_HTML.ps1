#Requires -Version 5.1
<#
.SYNOPSIS
    Converts XML security audit files to professional HTML reports

.DESCRIPTION
    This script parses XML security audit output and generates a professional HTML report
    with OffSec branding, dark blue styling, and interactive features.

.PARAMETER InputFile
    Path to the input XML audit file

.PARAMETER OutputFile
    Path for the output HTML file (default: audit_report.html)

.EXAMPLE
    .\Convert-SecurityAudit.ps1 -InputFile "audit.xml"
    
.EXAMPLE
    .\Convert-SecurityAudit.ps1 -InputFile "audit.xml" -OutputFile "offsec_report.html"
#>

param(
    [Parameter(Mandatory=$true, HelpMessage="Path to the input XML audit file")]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$InputFile,
    
    [Parameter(Mandatory=$false, HelpMessage="Path for the output HTML file")]
    [string]$OutputFile = "audit_report.html"
)

# Initialize variables
$ComputerInfo = @{}
$Collections = @()
$MissingUpdates = @()
$JavaVersions = @()
$FileDumps = @{}

function Format-CollectionName {
    param([string]$Name)
    
    $NameMap = @{
        'UserRightsAssignment' = 'User Rights Assignment'
        'SecurityOptions' = 'Security Options'
        'WindowsFirewall' = 'Windows Firewall'
        'AuditPolicy' = 'Audit Policy'
        'AccountPolicies' = 'Account Policies'
        'AdministrativeTemplates' = 'Administrative Templates'
        'Cryptography' = 'Cryptography'
        'CustomChecks' = 'Custom Security Checks'
        'MissingUpdates' = 'Missing Updates'
        'JavaBinaries' = 'Java Versions'
    }
    
    if ($NameMap.ContainsKey($Name)) {
        return $NameMap[$Name]
    }
    
    # Format CamelCase to spaced words
    return $Name -creplace '([A-Z])', ' $1' -replace '^ ', ''
}

function Parse-XmlAudit {
    param([string]$XmlFile)
    
    try {
        Write-Host "Parsing XML file: $XmlFile" -ForegroundColor Green
        [xml]$XmlContent = Get-Content $XmlFile -Raw
        
        # Extract Computer Information
        if ($XmlContent.Policy.ComputerInfo) {
            foreach ($ChildNode in $XmlContent.Policy.ComputerInfo.ChildNodes) {
                if ($ChildNode.NodeType -eq 'Element' -and $ChildNode.InnerText) {
                    $Script:ComputerInfo[$ChildNode.Name] = $ChildNode.InnerText
                }
            }
        }
        
        # Extract Policy Collections
        foreach ($Collection in $XmlContent.Policy.Collection) {
            $CollectionData = @{
                Name = $Collection.Name
                Groups = @()
                Status = 'Pass'
            }
            
            foreach ($Group in $Collection.Group) {
                $GroupData = @{
                    Name = $Group.Name
                    Status = $Group.GroupResult
                    Checks = @()
                    Results = @()
                }
                
                # Update collection status if any group fails
                if ($Group.GroupResult -eq 'Fail') {
                    $CollectionData.Status = 'Fail'
                }
                
                # Extract Checks
                foreach ($Check in $Group.Check) {
                    $CheckData = @{
                        CID = $Check.CID
                        Name = $Check.Name
                        Value = $Check.Value
                        Comparison = $Check.Comparison
                        Type = $Check.Type
                        Requirements = $Check.Requirements
                        Hive = $Check.Hive
                        Path = $Check.Path
                    }
                    $GroupData.Checks += $CheckData
                }
                
                # Extract Results (for special collections like MissingUpdates)
                if ($Group.Results.Result) {
                    foreach ($Result in $Group.Results.Result) {
                        $ResultData = @{}
                        foreach ($Attr in $Result.PSObject.Properties) {
                            if ($Attr.Name -ne '#text') {
                                $ResultData[$Attr.Name] = $Attr.Value
                            }
                        }
                        $GroupData.Results += $ResultData
                        
                        # Handle special collections
                        if ($Collection.Name -eq 'MissingUpdates') {
                            $Script:MissingUpdates += $ResultData
                        }
                        elseif ($Collection.Name -eq 'JavaBinaries') {
                            $Script:JavaVersions += $ResultData
                        }
                    }
                }
                
                $CollectionData.Groups += $GroupData
            }
            
            $Script:Collections += $CollectionData
        }
        
        # Extract File Dumps
        if ($XmlContent.Policy.FileDump.File) {
            foreach ($File in $XmlContent.Policy.FileDump.File) {
                $Script:FileDumps[$File.Name] = $File.'#text'
            }
        }
        
        return $true
    }
    catch {
        Write-Error "Error parsing XML: $($_.Exception.Message)"
        return $false
    }
}

function Generate-MissingUpdatesTable {
    if ($Script:MissingUpdates.Count -eq 0) {
        return ""
    }
    
    $Html = "<table>"
    $Html += "<thead><tr><th>Title</th><th>KB</th><th>Severity</th><th>Date Released</th><th>CVE</th></tr></thead><tbody>"
    
    foreach ($Update in $Script:MissingUpdates) {
        $Severity = $Update.Severity
        $SeverityClass = ""
        if ($Severity -eq 'Critical') { $SeverityClass = "critical" }
        elseif ($Severity -eq 'Important') { $SeverityClass = "important" }
        
        $DateReleased = if ($Update.DateReleased) { $Update.DateReleased.Split(' ')[0] } else { "" }
        
        $Html += @"
        <tr>
            <td>$($Update.Title)</td>
            <td>$($Update.KB)</td>
            <td><span class="$SeverityClass">$Severity</span></td>
            <td>$DateReleased</td>
            <td>$($Update.CVE)</td>
        </tr>
"@
    }
    
    $Html += "</tbody></table>"
    return $Html
}

function Generate-JavaVersionsTable {
    if ($Script:JavaVersions.Count -eq 0) {
        return ""
    }
    
    $Html = "<table>"
    $Html += "<thead><tr><th>File Path</th><th>Version</th><th>Product Name</th></tr></thead><tbody>"
    
    foreach ($Java in $Script:JavaVersions) {
        $Html += @"
        <tr>
            <td>$($Java.FileName)</td>
            <td>$($Java.FileVersion)</td>
            <td>$($Java.ProductName)</td>
        </tr>
"@
    }
    
    $Html += "</tbody></table>"
    return $Html
}

function Generate-CollectionDetails {
    param($Collection)
    
    $StatusClass = if ($Collection.Status -eq 'Pass') { 'pass' } else { 'fail' }
    $Html = "<p><strong>Status:</strong> <span class=`"$StatusClass`">$($Collection.Status)</span></p>"
    
    # Handle special collections
    if ($Collection.Name -eq 'MissingUpdates' -and $Script:MissingUpdates.Count -gt 0) {
        $Html += Generate-MissingUpdatesTable
    }
    elseif ($Collection.Name -eq 'JavaBinaries' -and $Script:JavaVersions.Count -gt 0) {
        $Html += Generate-JavaVersionsTable
    }
    else {
        # Regular collection with groups and checks
        foreach ($Group in $Collection.Groups) {
            if ($Group.Checks.Count -gt 0) {
                $GroupId = "$($Collection.Name.ToLower())-$($Group.Name.ToLower() -replace '\s+', '-')"
                $Html += "<h4 class='group-header expandable' onclick='toggleGroup(`"$GroupId`")'>$($Group.Name) - $($Group.Status) ($($Group.Checks.Count) checks) [Click to expand]</h4>"
                $Html += "<table id='$GroupId' class='checks-table' style='display: none;'>"
                
                # Check if we have registry entries to determine table columns
                $HasRegistryChecks = $Group.Checks | Where-Object { $_.Type -eq 'registry' -and ($_.Hive -or $_.Path) }
                
                if ($HasRegistryChecks) {
                    $Html += "<thead><tr><th style='width: 25%;'>Check Name</th><th style='width: 15%;'>Value</th><th style='width: 10%;'>Type</th><th style='width: 50%;'>Registry Path</th></tr></thead><tbody>"
                } else {
                    $Html += "<thead><tr><th style='width: 40%;'>Check Name</th><th style='width: 30%;'>Value</th><th style='width: 15%;'>Type</th><th style='width: 15%;'>Comparison</th></tr></thead><tbody>"
                }
                
                # Show all checks without truncation
                foreach ($Check in $Group.Checks) {
                    $CheckName = if ($Check.Name -like "*/*") { 
                        $Check.Name.Split('/')[-1] 
                    } else { 
                        $Check.Name 
                    }
                    
                    if ($HasRegistryChecks) {
                        $RegistryPath = ""
                        if ($Check.Hive -and $Check.Path) {
                            $RegistryPath = "$($Check.Hive)\$($Check.Path)"
                        } elseif ($Check.Path) {
                            $RegistryPath = $Check.Path
                        } elseif ($Check.Hive) {
                            $RegistryPath = $Check.Hive
                        }
                        
                        $Html += @"
                        <tr>
                            <td class="check-name" data-label="Check Name">$CheckName</td>
                            <td class="check-value" data-label="Value">$($Check.Value)</td>
                            <td data-label="Type">$($Check.Type)</td>
                            <td class="registry-path" data-label="Registry Path">$RegistryPath</td>
                        </tr>
"@
                    } else {
                        $Html += @"
                        <tr>
                            <td class="check-name" data-label="Check Name">$CheckName</td>
                            <td class="check-value" data-label="Value">$($Check.Value)</td>
                            <td data-label="Type">$($Check.Type)</td>
                            <td data-label="Comparison">$($Check.Comparison)</td>
                        </tr>
"@
                    }
                }
                
                $Html += "</tbody></table>"
            }
        }
    }
    
    # Add copy button
    $CollectionId = "$($Collection.Name.ToLower())-content"
    $Html += "<button class='copy-btn' onclick='copyToClipboard(`"$CollectionId`")'>Copy Details</button>"
    
    # Hidden content for copying
    $CopyContent = "$(Format-CollectionName $Collection.Name): $($Collection.Status)"
    if ($Collection.Name -eq 'MissingUpdates') {
        $CopyContent += "`n$($Script:MissingUpdates.Count) missing updates found"
        foreach ($Update in $Script:MissingUpdates) {
            $CopyContent += "`n- $($Update.Title) ($($Update.KB)) - $($Update.Severity)"
        }
    }
    elseif ($Collection.Name -eq 'JavaBinaries') {
        $CopyContent += "`n$($Script:JavaVersions.Count) Java versions found"
        foreach ($Java in $Script:JavaVersions) {
            $CopyContent += "`n- $($Java.ProductName) $($Java.FileVersion) at $($Java.FileName)"
        }
    }
    else {
        # Add group details for other collections
        foreach ($Group in $Collection.Groups) {
            if ($Group.Checks.Count -gt 0) {
                $CopyContent += "`n`n$($Group.Name) - $($Group.Status) ($($Group.Checks.Count) checks)"
                $RegistryChecks = $Group.Checks | Where-Object { $_.Type -eq 'registry' -and ($_.Hive -or $_.Path) }
                if ($RegistryChecks.Count -gt 0) {
                    $CopyContent += "`nKey Registry Settings:"
                    foreach ($Check in $RegistryChecks | Select-Object -First 5) {
                        $RegPath = if ($Check.Hive -and $Check.Path) { "$($Check.Hive)\$($Check.Path)" } else { $Check.Path }
                        $CopyContent += "`n- $($Check.Name): $($Check.Value) at $RegPath"
                    }
                    if ($RegistryChecks.Count -gt 5) {
                        $CopyContent += "`n- ... and $($RegistryChecks.Count - 5) more registry settings"
                    }
                }
            }
        }
    }
    
    $Html += "<div id='$CollectionId' style='display:none;'>$CopyContent</div>"
    
    return $Html
}

function Generate-Recommendations {
    $CriticalUpdates = $Script:MissingUpdates | Where-Object { $_.Severity -eq 'Critical' }
    $ImportantUpdates = $Script:MissingUpdates | Where-Object { $_.Severity -eq 'Important' }
    
    $Html = @"
            <div class="section">
                <div class="section-header">
                    <span class="section-title">Recommendations</span>
                </div>
                <div class="details" style="display: block;">
"@
    
    if ($CriticalUpdates.Count -gt 0 -or $ImportantUpdates.Count -gt 0 -or $Script:JavaVersions.Count -gt 0) {
        $Html += "<h3>Immediate Actions Required:</h3><ol>"
        
        if ($CriticalUpdates.Count -gt 0) {
            $Html += "<li><strong>Critical Updates:</strong> Install $($CriticalUpdates.Count) critical security updates immediately</li>"
        }
        
        if ($ImportantUpdates.Count -gt 0) {
            $Html += "<li><strong>Important Updates:</strong> Install $($ImportantUpdates.Count) important security updates</li>"
        }
        
        if ($Script:JavaVersions.Count -gt 0) {
            $Html += "<li><strong>Java Updates:</strong> Review and update $($Script:JavaVersions.Count) Java installations</li>"
        }
        
        $Html += "</ol>"
    }
    
    $Html += @"
                    <h3>Ongoing Maintenance:</h3>
                    <ul>
                        <li>Implement automated patch management for critical and security updates</li>
                        <li>Regular review of installed software versions</li>
                        <li>Monitor security advisories for installed software</li>
                        <li>Consider removing unused software to reduce attack surface</li>
                    </ul>
                </div>
            </div>
"@
    
    return $Html
}

function Generate-HtmlReport {
    param([string]$OutputPath)
    
    # Calculate statistics
    $TotalCollections = $Script:Collections.Count
    $PassingCollections = ($Script:Collections | Where-Object { $_.Status -eq 'Pass' }).Count
    $FailingCollections = $TotalCollections - $PassingCollections
    $OverallStatus = if ($FailingCollections -eq 0) { "PASS" } else { "FAIL" }
    
    $HostName = if ($Script:ComputerInfo.HostName) { $Script:ComputerInfo.HostName } else { "Unknown" }
    $CurrentDate = Get-Date -Format "MMMM dd, yyyy"
    
    # Start building HTML
    $Html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OffSec Security Audit Report - $HostName</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
            line-height: 1.6;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 4px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .header {
            background: #1a237e;
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            margin: 0;
            font-size: 2.5em;
            font-weight: 300;
        }
        
        .header .subtitle {
            margin: 10px 0 0 0;
            opacity: 0.9;
            font-size: 1.1em;
        }
        
        .content {
            padding: 30px;
        }
        
        .summary {
            background: #f8f9fa;
            border-radius: 4px;
            padding: 20px;
            margin-bottom: 30px;
            border-left: 4px solid #1a237e;
        }
        
        .summary h2 {
            margin-top: 0;
            color: #333;
        }
        
        .computer-info {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .info-item {
            background: white;
            padding: 10px;
            border-radius: 2px;
            border: 1px solid #e0e0e0;
        }
        
        .info-label {
            font-weight: bold;
            color: #555;
            display: block;
            margin-bottom: 5px;
        }
        
        .info-value {
            color: #333;
            word-wrap: break-word;
            word-break: break-all;
            overflow-wrap: break-word;
            max-width: 100%;
        }
        
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
            margin-top: 20px;
        }
        
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 4px;
            text-align: center;
            border: 1px solid #e0e0e0;
        }
        
        .stat-number {
            font-size: 2em;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .stat-label {
            color: #666;
            font-size: 0.9em;
        }
        
        .pass { color: #28a745; }
        .fail { color: #dc3545; }
        .critical { color: #dc3545; font-weight: bold; }
        .important { color: #fd7e14; font-weight: bold; }
        
        .section {
            margin-bottom: 40px;
        }
        
        .section-header {
            background: #1a237e;
            color: white;
            padding: 15px 20px;
            margin-bottom: 0;
            border-radius: 4px 4px 0 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
            cursor: pointer;
            transition: background-color 0.3s;
        }
        
        .section-header:hover {
            background: #0d47a1;
        }
        
        .section-title {
            font-size: 1.4em;
            font-weight: 500;
        }
        
        .section-status {
            background: rgba(255,255,255,0.2);
            padding: 5px 15px;
            border-radius: 2px;
            font-size: 0.9em;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
            background: white;
            table-layout: fixed;
        }
        
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #e0e0e0;
            word-wrap: break-word;
            word-break: break-word;
            max-width: 300px;
        }
        
        th {
            background: #f8f9fa;
            font-weight: 600;
            color: #333;
            position: sticky;
            top: 0;
        }
        
        .check-name {
            font-weight: 500;
            color: #333;
        }
        
        .check-value {
            font-family: monospace;
            font-size: 0.9em;
            background: #f8f9fa;
            padding: 2px 6px;
            border-radius: 2px;
        }
        
        .registry-path {
            font-family: monospace;
            font-size: 0.85em;
            color: #666;
            word-break: break-all;
            background: #f1f3f4;
            padding: 4px 6px;
            border-radius: 2px;
        }
        
        .filter-buttons {
            margin-bottom: 20px;
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        
        .filter-btn {
            padding: 8px 16px;
            border: 1px solid #ddd;
            background: white;
            color: #333;
            border-radius: 2px;
            cursor: pointer;
            transition: all 0.3s;
        }
        
        .filter-btn:hover {
            background: #f8f9fa;
        }
        
        .filter-btn.active {
            background: #1a237e;
            color: white;
            border-color: #1a237e;
        }
        
        .details {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 0 0 4px 4px;
            border-top: 1px solid #e0e0e0;
            display: none;
        }
        
        .missing-updates {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 4px;
            padding: 20px;
            margin-bottom: 20px;
        }
        
        .copy-btn {
            background: #28a745;
            color: white;
            border: none;
            padding: 5px 10px;
            border-radius: 2px;
            cursor: pointer;
            font-size: 0.8em;
            margin-left: 10px;
        }
        
        .copy-btn:hover {
            background: #218838;
        }
        
        .checks-table {
            margin-top: 15px;
        }
        
        .group-header {
            background: #e3f2fd;
            padding: 10px;
            margin: 10px 0 5px 0;
            border-radius: 4px;
            border-left: 4px solid #1a237e;
            cursor: pointer;
            transition: background-color 0.3s;
        }
        
        .group-header:hover {
            background: #bbdefb;
        }
        
        @media (max-width: 768px) {
            .container {
                margin: 10px;
                border-radius: 0;
            }
            
            .content {
                padding: 15px;
            }
            
            .computer-info {
                grid-template-columns: 1fr;
            }
            
            table {
                font-size: 0.9em;
            }
            
            th, td {
                padding: 8px;
            }
            
            /* Stack table on mobile for better readability */
            .checks-table thead {
                display: none;
            }
            
            .checks-table, .checks-table tbody, .checks-table tr, .checks-table td {
                display: block;
                width: 100%;
            }
            
            .checks-table tr {
                border: 1px solid #ccc;
                margin-bottom: 10px;
                padding: 10px;
                border-radius: 4px;
            }
            
            .checks-table td {
                border: none;
                padding: 5px 0;
                text-align: left;
            }
            
            .checks-table td:before {
                content: attr(data-label) ": ";
                font-weight: bold;
                color: #555;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>OffSec Security Audit Report</h1>
            <div class="subtitle">Host: $HostName | Date: $CurrentDate</div>
        </div>
        
        <div class="content">
            <!-- Summary Section -->
            <div class="summary">
                <h2>Executive Summary</h2>
                <div class="computer-info">
"@

    # Add computer info
    foreach ($Key in $Script:ComputerInfo.Keys) {
        $Value = $Script:ComputerInfo[$Key]
        if ($Key -and $Value) {
            $FormattedKey = $Key -creplace '([A-Z])', ' $1' -replace '^ ', ''
            $Html += @"
                    <div class="info-item">
                        <span class="info-label">${FormattedKey}:</span>
                        <span class="info-value">$Value</span>
                    </div>
"@
        }
    }

    $OverallStatusClass = if ($OverallStatus -eq 'PASS') { 'pass' } else { 'fail' }
    $PassingStatusClass = if ($PassingCollections -eq $TotalCollections) { 'pass' } else { 'fail' }

    $Html += @"
                </div>
                
                <div class="stats">
                    <div class="stat-card">
                        <div class="stat-number $OverallStatusClass">$OverallStatus</div>
                        <div class="stat-label">Overall Status</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-number">$TotalCollections</div>
                        <div class="stat-label">Policy Collections</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-number $PassingStatusClass">$PassingCollections</div>
                        <div class="stat-label">Passing Collections</div>
                    </div>
"@

    if ($Script:MissingUpdates.Count -gt 0) {
        $Html += @"
                    <div class="stat-card">
                        <div class="stat-number fail">$($Script:MissingUpdates.Count)</div>
                        <div class="stat-label">Missing Updates</div>
                    </div>
"@
    }

    if ($Script:JavaVersions.Count -gt 0) {
        $Html += @"
                    <div class="stat-card">
                        <div class="stat-number fail">$($Script:JavaVersions.Count)</div>
                        <div class="stat-label">Java Versions</div>
                    </div>
"@
    }

    $Html += @"
                </div>
            </div>

            <!-- Filter Buttons -->
            <div class="filter-buttons">
                <button class="filter-btn active" onclick="filterSections('all')">All Sections</button>
                <button class="filter-btn" onclick="filterSections('pass')">Passing Only</button>
                <button class="filter-btn" onclick="filterSections('fail')">Failed Only</button>
                <button class="filter-btn" onclick="filterSections('critical')">Critical Issues</button>
            </div>

            <!-- Policy Collections -->
"@

    # Generate sections for each collection
    foreach ($Collection in $Script:Collections) {
        $StatusClass = if ($Collection.Status -eq 'Pass') { 'pass' } else { 'fail' }
        $SectionClass = if ($Collection.Name -eq 'MissingUpdates' -and $Collection.Status -eq 'Fail') { 'missing-updates' } else { '' }
        $IsCritical = ($Collection.Name -eq 'MissingUpdates' -and $Script:MissingUpdates.Count -gt 0) -or 
                     ($Collection.Name -eq 'JavaBinaries' -and $Script:JavaVersions.Count -gt 0)
        $CriticalAttr = if ($IsCritical) { 'data-critical="true"' } else { '' }
        $CollectionTitle = Format-CollectionName $Collection.Name
        $SectionId = $Collection.Name.ToLower()
        
        $Html += @"
            <div class="section $SectionClass" data-status="$StatusClass" $CriticalAttr>
                <div class="section-header" onclick="toggleSection('$SectionId')">
                    <span class="section-title">$CollectionTitle</span>
                    <span class="section-status $StatusClass">$($Collection.Status.ToUpper())</span>
                </div>
                <div id="$SectionId" class="details">
"@
        
        $Html += Generate-CollectionDetails $Collection
        
        $Html += @"
                </div>
            </div>
"@
    }

    # Add recommendations
    $Html += Generate-Recommendations

    # Add JavaScript and close HTML
    $Html += @"
        </div>
    </div>

    <script>
        function toggleSection(sectionId) {
            const section = document.getElementById(sectionId);
            section.style.display = section.style.display === 'none' ? 'block' : 'none';
        }

        function toggleGroup(groupId) {
            const group = document.getElementById(groupId);
            const header = event.target;
            
            if (group.style.display === 'none') {
                group.style.display = 'table';
                header.textContent = header.textContent.replace('[Click to expand]', '[Click to collapse]');
            } else {
                group.style.display = 'none';
                header.textContent = header.textContent.replace('[Click to collapse]', '[Click to expand]');
            }
        }

        function filterSections(filter) {
            // Update active button
            document.querySelectorAll('.filter-btn').forEach(btn => btn.classList.remove('active'));
            event.target.classList.add('active');
            
            const sections = document.querySelectorAll('.section');
            sections.forEach(section => {
                const status = section.getAttribute('data-status');
                const isCritical = section.getAttribute('data-critical') === 'true';
                
                if (filter === 'all') {
                    section.style.display = 'block';
                } else if (filter === 'pass' && status === 'pass') {
                    section.style.display = 'block';
                } else if (filter === 'fail' && status === 'fail') {
                    section.style.display = 'block';
                } else if (filter === 'critical' && isCritical) {
                    section.style.display = 'block';
                } else {
                    section.style.display = 'none';
                }
            });
        }

        function copyToClipboard(elementId) {
            const element = document.getElementById(elementId);
            const text = element.textContent;
            
            navigator.clipboard.writeText(text).then(() => {
                const btn = event.target;
                const originalText = btn.textContent;
                btn.textContent = 'Copied!';
                btn.style.background = '#28a745';
                
                setTimeout(() => {
                    btn.textContent = originalText;
                    btn.style.background = '#28a745';
                }, 2000);
            });
        }

        // Initialize
        document.addEventListener('DOMContentLoaded', function() {
            // All details start collapsed
            document.querySelectorAll('.details').forEach(detail => {
                detail.style.display = 'none';
            });
        });
    </script>
</body>
</html>
"@

    try {
        $Html | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "HTML report generated successfully: $OutputPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Error writing HTML file: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
try {
    Write-Host "OffSec Security Audit Report Converter" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    
    if (-not (Parse-XmlAudit $InputFile)) {
        Write-Error "Failed to parse XML file"
        exit 1
    }
    
    Write-Host "Generating HTML report: $OutputFile" -ForegroundColor Yellow
    
    if (-not (Generate-HtmlReport $OutputFile)) {
        Write-Error "Failed to generate HTML report"
        exit 1
    }
    
    Write-Host "Conversion completed successfully!" -ForegroundColor Green
    Write-Host "Report saved to: $OutputFile" -ForegroundColor Green
    
    # Ask if user wants to open the report
    $OpenReport = Read-Host "Would you like to open the report now? (Y/N)"
    if ($OpenReport -match '^[Yy]') {
        Start-Process $OutputFile
    }
}
catch {
    Write-Error "Unexpected error: $($_.Exception.Message)"
    exit 1
}