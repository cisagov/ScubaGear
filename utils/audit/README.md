# PowerShell Parallel Processing Framework

This repository contains a powerful PowerShell-based parallel processing framework designed for efficient handling of large-scale operations, with a specific implementation for Exchange Online mailbox processing.

## Overview

The framework consists of two main components:

1. **Runspaces Framework** (`RunspaceTools.ps1`) - A reusable producer/consumer pattern implementation using PowerShell runspaces for parallel processing.
2. **Exchange Online Mailbox Processor** (`mailbox-parallel.txt`) - A practical implementation that leverages the framework to efficiently process Exchange Online mailboxes.

## Runspaces Framework

The core parallel processing framework (`RunspaceTools.ps1`) provides a flexible and efficient way to process large collections of items concurrently. It uses PowerShell runspaces to create a pool of workers that can process batches of items in parallel.

### Key Features

- **Configurable Parallelism**: Set the maximum number of concurrent runspaces
- **Batch Processing**: Items are processed in configurable batch sizes for optimal performance
- **Progress Reporting**: Built-in progress tracking and reporting
- **Result Collection**: Comprehensive collection of processing results
- **Error Handling**: Robust error management with detailed reporting
- **Export Capabilities**: Optional export of results and errors to files

### Core Functions

- `New-ParallelRunner`: Creates a new parallel processing runner
- `Add-ParallelItems`: Adds items to the processing queue
- `Split-IntoBatches`: Divides input items into manageable batches
- `Start-ParallelJob`: Starts a parallel job for a batch
- `Process-CompletedJob`: Handles completed jobs
- `Invoke-ParallelProcessing`: Main function that orchestrates the entire parallel processing workflow

## Exchange Online Mailbox Processor

The Exchange Online implementation (`mailbox-parallel.txt`) demonstrates how to use the framework to efficiently process Exchange Online mailboxes. It handles connection management, mailbox retrieval, and delegates the processing to the parallel framework.

### Features

- **Exchange Online Integration**: Automatically connects to Exchange Online if needed
- **Efficient Property Retrieval**: Uses PropertySets for optimized mailbox data retrieval
- **Comprehensive Reporting**: Provides detailed processing statistics
- **Data Aggregation**: Collects and summarizes mailbox information
- **Error Handling**: Captures and reports Exchange-specific errors

## Usage Example

1. First, ensure both files are in the same directory
2. Run the mailbox processing script:

```powershell
# Import the runspaces framework
. ./RunspaceTools.ps1

# Run the mailbox processor
. ./MailboxProcessor.ps1
