# Parallel Processing Framework with Runspaces (Hashtable-based)
# This module provides a reusable framework for parallel processing using the producer/consumer pattern

function New-ParallelRunner {
    param (
        [int]$MaxRunspaces = 4,
        [int]$BatchSize = 10,
        [scriptblock]$ProcessingScript
    )
    
    # Create the runner object as a hashtable
    $runner = @{
        MaxRunspaces = $MaxRunspaces
        BatchSize = $BatchSize
        ProcessingScript = $ProcessingScript
        InputQueue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
        OutputQueue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
        Jobs = @{}
        IsComplete = $false
        TotalProcessed = 0
        BatchCounter = 0
        TotalItems = 0
    }
    
    # Initialize runspace pool
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(
        1,                  # Min Runspaces
        $MaxRunspaces,      # Max Runspaces
        $sessionState,
        $global:Host
    )
    $runspacePool.Open()
    $runner.RunspacePool = $runspacePool
    
    return $runner
}

function Add-ParallelItems {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Runner,
        
        [Parameter(Mandatory = $true)]
        [array]$Items
    )
    
    $Runner.TotalItems = $Items.Count
    $batches = Split-IntoBatches -InputList $Items -BatchSize $Runner.BatchSize
    
    foreach ($batch in $batches) {
        $Runner.BatchCounter++
        $batchJob = @{
            Id = $Runner.BatchCounter
            Items = $batch
            Count = $batch.Count
            EnqueueTime = Get-Date
        }
        $Runner.InputQueue.Enqueue($batchJob)
    }
    
    Write-Host "Created $($batches.Count) batches (batch size: $($Runner.BatchSize))" -ForegroundColor Cyan
}

function Split-IntoBatches {
    param (
        [Parameter(Mandatory = $true)]
        [array]$InputList,
        
        [Parameter(Mandatory = $true)]
        [int]$BatchSize
    )
    
    $batchCount = [Math]::Ceiling($InputList.Count / $BatchSize)
    $batches = @()
    
    for ($i = 0; $i -lt $batchCount; $i++) {
        $startIndex = $i * $BatchSize
        $count = [Math]::Min($BatchSize, ($InputList.Count - $startIndex))
        $batches += ,@($InputList | Select-Object -Skip $startIndex -First $count)
    }
    
    return $batches
}

function Start-ParallelJob {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Runner,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$BatchJob
    )
    
    $powerShell = [powershell]::Create().AddScript($Runner.ProcessingScript)
    $powerShell.AddArgument($BatchJob)
    $powerShell.AddArgument($Runner.OutputQueue)
    $powerShell.RunspacePool = $Runner.RunspacePool
    
    $asyncResult = $powerShell.BeginInvoke()
    $jobInfo = @{
        AsyncResult = $asyncResult
        PowerShell = $powerShell
        Id = $BatchJob.Id
        StartTime = Get-Date
        BatchSize = $BatchJob.Count
    }
    
    $Runner.Jobs[$BatchJob.Id] = $jobInfo
    #Write-Host "Started processing batch $($BatchJob.Id) with $($BatchJob.Count) items" -ForegroundColor Cyan
}

function Process-CompletedJob {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Runner,
        
        [Parameter(Mandatory = $true)]
        [int]$JobId
    )
    
    $jobInfo = $Runner.Jobs[$JobId]
    
    try {
        $jobInfo.PowerShell.EndInvoke($jobInfo.AsyncResult)
        $processingTime = (Get-Date) - $jobInfo.StartTime
        $Runner.TotalProcessed += $jobInfo.BatchSize
        
        #Write-Host "Completed batch $JobId ($($jobInfo.BatchSize) items) in $($processingTime.TotalSeconds.ToString("0.00")) seconds" -ForegroundColor Green
    }
    catch {
        #Write-Host "Error processing batch $JobId`: $_" -ForegroundColor Red
    }
    finally {
        # Clean up
        $jobInfo.PowerShell.Dispose()
        $Runner.Jobs.Remove($JobId)
    }
}

function Invoke-ParallelProcessing {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Items,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ProcessingScript,
        
        [Parameter()]
        [int]$MaxRunspaces = 4,
        
        [Parameter()]
        [int]$BatchSize = 10,
        
        [Parameter()]
        [string]$ActivityName = "Processing Items",
        
        [Parameter()]
        [switch]$ExportResults,
        
        [Parameter()]
        [string]$ResultsPath,
        
        [Parameter()]
        [string]$ErrorsPath
    )
    
    # Create and configure parallel runner
    $runner = New-ParallelRunner -MaxRunspaces $MaxRunspaces -BatchSize $BatchSize -ProcessingScript $ProcessingScript
    Add-ParallelItems -Runner $runner -Items $Items
    
    #Write-Host "Starting batch processing with $($runner.MaxRunspaces) parallel workers..." -ForegroundColor Yellow
    
    # Variables for TryDequeue
    $batch = $null
    $result = $null
    
    # Main processing loop
    while ($runner.InputQueue.Count -gt 0 -or $runner.Jobs.Count -gt 0) {
        # Start new jobs if runspaces are available
        while ($runner.Jobs.Count -lt $runner.MaxRunspaces -and $runner.InputQueue.Count -gt 0) {
            if ($runner.InputQueue.TryDequeue([ref]$batch)) {
                Start-ParallelJob -Runner $runner -BatchJob $batch
            }
        }
        
        # Check for completed jobs
        $completedJobs = @($runner.Jobs.Keys | Where-Object { $runner.Jobs[$_].AsyncResult.IsCompleted })
        
        foreach ($jobId in $completedJobs) {
            Process-CompletedJob -Runner $runner -JobId $jobId
        }
        
        # Report progress
        if ($runner.TotalItems -gt 0) {
            $percentComplete = [Math]::Min(100, [Math]::Round(($runner.TotalProcessed / $runner.TotalItems) * 100))
            Write-Progress -Activity $ActivityName -Status "$($runner.TotalProcessed) / $($runner.TotalItems) items processed" -PercentComplete $percentComplete
        }
        
        # Brief pause to reduce CPU usage
        if ($runner.Jobs.Count -gt 0) {
            Start-Sleep -Milliseconds 100
        }
    }
    
    # Mark processing as complete
    $runner.IsComplete = $true
    Write-Progress -Activity $ActivityName -Completed
    
    # Collect all results
    $allResults = @()
    #Write-Host "Collecting results from output queue. Queue size: $($runner.OutputQueue.Count)" -ForegroundColor Cyan
    while ($runner.OutputQueue.Count -gt 0) {
        if ($runner.OutputQueue.TryDequeue([ref]$result)) {
            #Write-Host "Dequeued result for batch $($result.BatchId) with $($result.ProcessedItems.Count) items" -ForegroundColor DarkCyan
            $allResults += $result
        }
        else {
            #Write-Host "Failed to dequeue result" -ForegroundColor Red
            Start-Sleep -Milliseconds 100
        }
    }
    #Write-Host "Collected $($allResults.Count) results from queue" -ForegroundColor Cyan
    
    # Generate summary report
    $successfulItems = [int]($allResults | Measure-Object -Property SuccessCount -Sum).Sum
    $failedItems = [int]($allResults | Measure-Object -Property ErrorCount -Sum).Sum
    $processedTotal = $successfulItems + $failedItems
    $avgMeasure = $allResults | Measure-Object -Property Duration -Average
    $averageBatchTime = if ($avgMeasure.Average) { $avgMeasure.Average } else { 0 }
    
    Write-Host "`n===== SUMMARY REPORT =====" -ForegroundColor Magenta
    Write-Host "Total items processed: $processedTotal" -ForegroundColor White
    Write-Host "Successful items: $successfulItems" -ForegroundColor Green
    Write-Host "Failed items: $failedItems" -ForegroundColor $(if ($failedItems -gt 0) { "Red" } else { "Green" })
    Write-Host "Average batch processing time: $($averageBatchTime.ToString("0.00")) seconds" -ForegroundColor Cyan
    Write-Host "Total batches: $($allResults.Count)" -ForegroundColor White
    
    # Export results if requested
    if ($ExportResults) {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        
        # Extract all processed items
        $processedItems = @()
        foreach ($res in $allResults) {
            if ($res.ProcessedItems -and $res.ProcessedItems.Count -gt 0) {
                $processedItems += $res.ProcessedItems
            }
        }
        
        Write-Host "Found $($processedItems.Count) successful items to export" -ForegroundColor Cyan
        
        if ($processedItems.Count -gt 0) {
            $resultsFilePath = if ($ResultsPath) { $ResultsPath } else { Join-Path -Path $PWD -ChildPath "$($ActivityName)_Results_$timestamp.csv" }
            $processedItems | Export-Csv -Path $resultsFilePath -NoTypeInformation
            Write-Host "Exported results to: $resultsFilePath" -ForegroundColor Green
        }
        
        # Extract all errors
        $errors = @()
        foreach ($res in $allResults) {
            if ($res.Errors -and $res.Errors.Count -gt 0) {
                $errors += $res.Errors
            }
        }
        
        Write-Host "Found $($errors.Count) errors to export" -ForegroundColor Cyan
        
        if ($errors.Count -gt 0) {
            $errorsFilePath = if ($ErrorsPath) { $ErrorsPath } else { Join-Path -Path $PWD -ChildPath "$($ActivityName)_Errors_$timestamp.log" }
            $errors | Out-File -FilePath $errorsFilePath
            Write-Host "Exported error details to: $errorsFilePath" -ForegroundColor Yellow
        }
    }
    
    # Cleanup
    $runner.RunspacePool.Close()
    $runner.RunspacePool.Dispose()
    
    # Debug information
    Write-Host "DEBUG: Results variable has $($allResults.Count) items" -ForegroundColor Magenta
    if ($allResults.Count -gt 0) {
        Write-Host "DEBUG: First result batch ID: $($allResults[0].BatchId)" -ForegroundColor Magenta
        Write-Host "DEBUG: First result has $($allResults[0].ProcessedItems.Count) processed items" -ForegroundColor Magenta
    }
    
    Write-Host "Returning results from function..." -ForegroundColor Cyan
    return $allResults
}
