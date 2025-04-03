# Exchange Online Mailbox Processing with Fixed Parallel Framework

# Import the parallel processing framework
. ./RunspaceTools.ps1

# Check for Exchange Online Management module
if (-not (Get-Module -Name ExchangeOnlineManagement -ListAvailable)) {
    Write-Host "ExchangeOnlineManagement module is required. Install it using:" -ForegroundColor Red
    Write-Host "Install-Module -Name ExchangeOnlineManagement -Force" -ForegroundColor Yellow
    exit
}

# Import and connect to Exchange Online if needed
if (-not (Get-Module -Name ExchangeOnlineManagement)) {
    Import-Module ExchangeOnlineManagement
    Write-Host "Imported ExchangeOnlineManagement module" -ForegroundColor Green
}

# Check connection status
$ExoConnectionStatus = Get-ConnectionInformation -ErrorAction SilentlyContinue
if (-not $ExoConnectionStatus) {
    Write-Host "Not connected to Exchange Online. Connecting..." -ForegroundColor Yellow
    Connect-ExchangeOnline -ShowBanner:$false
}
else {
    Write-Host "Already connected to Exchange Online as $($ExoConnectionStatus.UserPrincipalName)" -ForegroundColor Green
}

# Get mailboxes to process
Write-Host "Gathering user identities for mailbox processing..." -ForegroundColor Cyan
$AllUsers = (Get-EXORecipient -ResultSize unlimited -RecipientTypeDetails UserMailbox).PrimarySmtpAddress

# Define the processing script
$MailboxProcessingScript = {
    param($BatchJob, $OutputQueue)
    
    # Import the required module in the runspace
    Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
    
    # Create a result hashtable
    $result = @{
        BatchId = $BatchJob.Id
        ProcessedCount = 0
        SuccessCount = 0
        ErrorCount = 0
        StartTime = Get-Date
        EndTime = $null
        Duration = $null
        ProcessedItems = @()
        Errors = @()
    }
    
    try {
        # These are the properties we want to retrieve efficiently
        $PropertySets = @('Audit')
        $Properties = @('RecipientType')
        
        #Write-Host "Processing batch $($BatchJob.Id) with $($BatchJob.Items.Count) users" -ForegroundColor Cyan
        
        # Process each user in the batch
        foreach ($User in $BatchJob.Items) {
            try {
                # Try to get real mailbox data if connected
                $Mailbox = Get-EXOMailbox -Identity $User -PropertySets $PropertySets -Properties $Properties -ErrorAction Stop
                # Extract only the properties we need
                $processedMailbox = @{
                    Email = $Mailbox.PrimarySmtpAddress
                    AuditEnabled = $Mailbox.AuditEnabled
                    AuditAdmin = $Mailbox.AuditAdmin
                    AuditDelegate = $Mailbox.AuditDelegate
                    AuditOwner = $Mailbox.AuditOwner
                    DefaultAuditSet = $Mailbox.DefaultAuditSet
                }
                
                # Add to processed items
                $result.ProcessedItems += $processedMailbox
                $result.ProcessedCount++
                $result.SuccessCount++
            }
            catch {
                $errorMessage = "Error getting mailbox for $User`: $_"
                $result.Errors += $errorMessage
                $result.ErrorCount++
            }
        }
        
        #Write-Host "Processed $($result.ProcessedItems.Count) mailboxes in batch $($BatchJob.Id)" -ForegroundColor Green
    }
    catch {
        $errorMessage = "Batch processing error: $_"
        $result.Errors += $errorMessage
        $result.ErrorCount++
    }
    finally {
        # Complete the result and add to output queue
        $result.EndTime = Get-Date
        $result.Duration = ($result.EndTime - $result.StartTime).TotalSeconds
        
        $OutputQueue.Enqueue($result)
        #Write-Host "Batch $($BatchJob.Id) result added to output queue" -ForegroundColor Cyan
    }
}

# Run the parallel processing
Write-Host "Calling Invoke-ParallelProcessing..." -ForegroundColor Yellow
$Results = Invoke-ParallelProcessing -Items $AllUsers -ProcessingScript $MailboxProcessingScript `
    -MaxRunspaces 12 -BatchSize 20 -ActivityName "MailboxProcessing" -ExportResults -ResultsPath ./results.csv

# Explicitly show what we got back
Write-Host "Results returned to main script:" -ForegroundColor Yellow
Write-Host "- Type: $($Results.GetType().FullName)" -ForegroundColor Yellow
Write-Host "- Count: $($Results.Count)" -ForegroundColor Yellow

if ($Results.Count -gt 0) {
    # Calculate total processed items
    $totalProcessed = 0
    foreach ($result in $Results) {
        $totalProcessed += $result.ProcessedItems.Count
    }
    
    Write-Host "- Total processed items: $totalProcessed" -ForegroundColor Yellow
    
    # Access the processed items from all results
    $AllMailboxes = @()
    foreach ($result in $Results) {
        $AllMailboxes += $result.ProcessedItems
    }
    
    Write-Host "- All mailboxes count: $($AllMailboxes.Count)" -ForegroundColor Yellow
    
    # Show some sample mailboxes
    Write-Host "`nSample mailboxes:" -ForegroundColor Green
    $AllMailboxes | Select-Object -First 5 | Format-Table -AutoSize
    
    # Example: Group mailboxes by type
    $MailboxesByType = $AllMailboxes | Group-Object -Property Type
    
    Write-Host "`nMailboxes by type:" -ForegroundColor Green
    $MailboxesByType | Select-Object Name, Count | Format-Table -AutoSize
}
else {
    Write-Host "No results returned!" -ForegroundColor Red
}
