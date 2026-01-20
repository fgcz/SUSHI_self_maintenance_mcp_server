---
name: sushi
description: SUSHI Framework Complete Reference for MCP Server self-maintenance
version: "1.0.0"
layer: L1
tags: [sushi, fgcz, rails, ezrun, bioinformatics, slurm]
---

# SUSHI Framework Skills Document

## [TOC] Table of Contents

| Section ID | Title | Use When |
|------------|-------|----------|
| ARCH-010 | System Architecture | Understanding component relationships |
| ARCH-020 | Data Flow | Tracing job execution flow |
| INFRA-010 | Server Infrastructure | Finding server locations and URLs |
| INFRA-020 | Storage Layout | Locating files and paths |
| INFRA-030 | Environment Setup | Setting up shell environment |
| DEV-010 | App Development Overview | Creating new SUSHI apps |
| DEV-020 | R Method Structure | Writing ezRun R functions |
| DEV-030 | Ruby App Structure | Writing SUSHI Ruby frontend |
| DEV-040 | Rmd Templates | Creating report templates |
| DEV-050 | Parameter Passing | Ruby-to-R parameter mapping |
| DEV-060 | Coding Style | Following FGCZ conventions |
| CLI-010 | sushi_fabric Command | Programmatic job submission |
| CLI-020 | Dataset TSV Format | Creating input datasets |
| CLI-030 | Parameter TSV Format | Configuring job parameters |
| DEPLOY-010 | Test Instance Setup | Personal development testing |
| DEPLOY-020 | Production Deployment | Updating production SUSHI |
| DEPLOY-030 | Apache Configuration | Web server configuration |
| DB-010 | MySQL Operations | Database management |
| DB-020 | Backup and Restore | Data recovery |
| JOBMGR-010 | Job Manager Architecture | Understanding job submission |
| JOBMGR-020 | Job Manager Operations | Managing the job daemon |
| TROUBLE-010 | Common Issues | Quick diagnosis |
| TROUBLE-020 | Log Files | Finding diagnostic information |
| TROUBLE-030 | Database Debugging | SQL queries for diagnosis |
| REF-010 | Quick Reference | Frequently used commands |

---

## [ARCH-010] System Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Browser                              │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│              SUSHI Server (Ruby on Rails + Apache)               │
│  Host: fgcz-h-082 | Port: 8880 | Path: /srv/sushi/production/   │
│                                                                  │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────────┐ │
│  │ Controllers  │ │   Models     │ │     Services             │ │
│  │ - DataSet    │ │ - DataSet    │ │ - B-Fabric API           │ │
│  │ - RunApp     │ │ - Job        │ │ - gStore access          │ │
│  │ - JobMonitor │ │ - Project    │ │ - Dataset registration   │ │
│  └──────────────┘ └──────────────┘ └──────────────────────────┘ │
└───────────────────────────────┬─────────────────────────────────┘
                                │
           ┌────────────────────┼────────────────────┐
           │                    │                    │
           ▼                    ▼                    ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────────┐
│   MySQL Database │ │   Job Manager    │ │       gStore         │
│   (jobs table)   │ │   (Python)       │ │  /srv/gstore/        │
│                  │ │                  │ │                      │
│ - Job state      │ │ - sbatch submit  │ │ - Persistent storage │
│ - Dataset meta   │ │ - Status polling │ │ - g-req commands     │
└──────────────────┘ └────────┬─────────┘ └──────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Cluster Nodes (SLURM)                         │
│  Nodes: fgcz-c-041, 043, 044, 051, 053, 054, 176                │
│                                                                  │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────────┐ │
│  │ Module System│ │ ezRun Package│ │   Scratch Space          │ │
│  │ Dev/R/4.5.0  │ │ EzApp*       │ │   /scratch/              │ │
│  │ Tools/*      │ │ ezMethod*    │ │   Auto-cleanup           │ │
│  └──────────────┘ └──────────────┘ └──────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Web Framework | Ruby on Rails | 7.0.8.7 |
| Ruby | Ruby | 3.3.7 |
| Web Server | Apache + Passenger | 6.0.25 |
| Database | MySQL/MariaDB | 10.11 |
| Job Queue | MySQL-based (ActiveJob) | - |
| R Backend | ezRun package | current |

---

## [ARCH-020] Data Flow

### Job Submission Flow

```
1. User selects DataSet in web UI
           │
           ▼
2. User configures parameters
           │
           ▼
3. RunApplicationController#submit_jobs
           │
           ▼
4. SubmitJob (ActiveJob) queued
           │
           ▼
5. Job record created in MySQL jobs table
           │
           ▼
6. Job Manager (Python) polls jobs table
           │
           ▼
7. Job Manager submits to SLURM via sbatch
           │
           ▼
8. Job executes on cluster node (ezRun R package)
           │
           ▼
9. Results copied to gStore (g-req)
           │
           ▼
10. Output DataSet created in SUSHI
           │
           ▼
11. B-Fabric dataset registration (optional)
```

### Job Script Structure (Generated)

```bash
#!/bin/bash
#SBATCH --job-name=AppName_pXXXXX
#SBATCH --output=/srv/gstore/projects/pXXXXX/.../stdout.txt
#SBATCH --error=/srv/gstore/projects/pXXXXX/.../stderr.txt
#SBATCH --time=24:00:00
#SBATCH --mem-per-cpu=8G
#SBATCH --cpus-per-task=8
#SBATCH --partition=employee

# Load modules
source /usr/local/ngseq/etc/lmod_profile
module load Dev/R/4.5.0

# Setup conda
eval "$(/usr/local/ngseq/miniforge3/bin/conda shell.bash hook)"
conda activate gi_py3.12.8

# Run R application
Rscript -e "
library(ezRun)
EzAppName\$new()\$run(
  input = EzDataset\$new(file='input_dataset.tsv'),
  output = EzDataset\$new(file='output_dataset.tsv'),
  param = readRDS('parameters.rds')
)
"
```

---

## [INFRA-010] Server Infrastructure

### Server Instances

| Instance | URL | Internal Access | Host | Path |
|----------|-----|-----------------|------|------|
| **Production** | https://fgcz-sushi.uzh.ch | http://fgcz-h-082:8880 | fgcz-h-082 | `/srv/sushi/production/` |
| **Demo** | https://fgcz-sushi-demo.uzh.ch | http://fgcz-h-081:8880 | fgcz-h-081 | `/srv/sushi/demo_sushi/` |
| **Course** | https://fgcz-course1.bfabric.org | http://fgcz-h-081:8881 | fgcz-h-081 | `/srv/sushi/course_sushi/` |
| **Test** | VPN required | http://fgcz-h-083:5000 | fgcz-h-083 | `/srv/sushi/[user]_test_sushi_*` |

### Key Server Roles

| Purpose | Server |
|---------|--------|
| SLURM control | fgcz-h-034 |
| SUSHI production | fgcz-h-082 |
| SUSHI demo/course | fgcz-h-081 |
| SUSHI test | fgcz-h-083 |
| Development (install software) | fgcz-r-029 |
| GPU workloads | fgcz-r-023 |
| High-memory compute | fgcz-c-053, fgcz-c-054 |

---

## [INFRA-020] Storage Layout

| Path | Purpose | Access |
|------|---------|--------|
| `/srv/gstore/projects/pXXXXX/` | Long-term project storage | Read-only (use g-req) |
| `/srv/GT/analysis/pXXXXX/` | Working analysis directory | Read/write |
| `/srv/GT/reference/` | Reference genomes | Read-only |
| `/srv/GT/databases/` | Pfam, dbSNP, annotator | Read-only |
| `/scratch/` | Temporary job execution | Read/write (auto-cleanup) |
| `/misc/fgcz01/sushi/` | Shared SUSHI components | Setup scripts, configs |
| `/srv/sushi/` | SUSHI instances root | Per-host |

### URL Mappings

| Filesystem Path | Web URL |
|-----------------|---------|
| `/srv/gstore/projects/pXXXXX/file.html` | `https://fgcz-sushi.uzh.ch/projects/pXXXXX/file.html` |

---

## [INFRA-030] Environment Setup

### Standard Environment (All SUSHI Servers)

```bash
# Load module system
source /usr/local/ngseq/etc/lmod_profile
module load Dev/Ruby/3.3.7

# Activate conda
eval "$(/usr/local/ngseq/miniforge3/bin/conda shell.bash hook)"
conda activate gi_py3.12.8
```

### trxcopy .bash_profile (Production User)

```bash
if [ `hostname` = "fgcz-r-029" ] || [ `hostname` = "fgcz-h-081" ] || [ `hostname` = "fgcz-h-082" ]; then
  source /usr/local/ngseq/etc/lmod_profile
  module load Dev/Ruby/3.3.7
  . "/usr/local/ngseq/miniforge3/etc/profile.d/conda.sh"
  conda activate gi_py3.12.8
fi
```

---

## [DEV-010] App Development Overview

### Architecture Components

```
┌─────────────────────────────────────────────────────────────────┐
│              SUSHI (Ruby on Rails Frontend)                      │
│  - Web interface for job submission                              │
│  - Parameter definition (*.rb files in lib/)                     │
│  - Job queue management                                          │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                  ezRun (R Package Backend)                       │
│  - Core analysis code (R functions)                              │
│  - App classes (EzApp*) in ~/git/ezRun/R/                       │
│  - Rmd templates in ~/git/ezRun/inst/templates/                 │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Generated HTML Report                           │
│  - Uses FGCZ header/CSS from ezRun                              │
│  - Self-contained HTML output                                    │
└─────────────────────────────────────────────────────────────────┘
```

### Development Workflow

1. **Create R Method** (`~/git/ezRun/R/app-YourApp.R`)
2. **Create Ruby App** (`~/git/sushi/master/lib/YourAppApp.rb`)
3. **Create Rmd Template** (`~/git/ezRun/inst/templates/YourApp.Rmd`)
4. **Install ezRun** on fgcz-r-029
5. **Deploy Ruby App** to SUSHI server
6. **Test via SUSHI** web interface

---

## [DEV-020] R Method Structure

**Location**: `~/git/ezRun/R/app-YourApp.R`

```r
###################################################################
# Functional Genomics Center Zurich
# GNU General Public License Version 3

ezMethodYourApp <- function(input = NA, output = NA, param = NA,
                            htmlFile = "00index.html") {
  # 1. Load required packages
  ezLoadPackage('dplyr')
  ezLoadPackage('ggplot2')

  # 2. Set working directory
  setwdNew('YourApp')

  # 3. Get dataset metadata
  dataset <- input$meta

  # 4. Access input files
  inputPaths <- input$getFullPaths("ColumnName")

  # 5. Perform analysis
  results <- process_data(inputPaths, param)

  # 6. Save intermediate results
  ezWrite.table(results, file = 'results.tsv', row.names = FALSE)

  # 7. Save parameters for Rmd
  write_rds(param, 'param.rds')

  # 8. Generate report
  reportTitle <- 'Your App - Analysis Report'
  makeRmdReport(rmdFile = "YourApp.Rmd", reportTitle = reportTitle)

  return("Success")
}

##' @template app-template
EzAppYourApp <-
  setRefClass("EzAppYourApp",
    contains = "EzApp",
    methods = list(
      initialize = function() {
        runMethod <<- ezMethodYourApp
        name <<- "EzAppYourApp"
        appDefaults <<- rbind(
          customParam = ezFrame(
            Type = "character",
            DefaultValue = "default_value",
            Description = "Description of custom parameter."
          )
        )
      }
    )
  )
```

### Common ezRun Helper Functions

| Function | Purpose |
|----------|---------|
| `ezLoadPackage('pkg')` | Load package with error handling |
| `ezRead.table(file)` | Read tables with error handling |
| `ezWrite.table(data, file)` | Write tables with formatting |
| `ezLoadRobj(path)` | Load R objects (rds/qs2) |
| `setwdNew(dir)` | Change directory (creates if needed) |
| `ezMclapply(x, FUN)` | Parallel apply with ezRun defaults |
| `makeRmdReport(rmdFile, reportTitle)` | Generate HTML report |

---

## [DEV-030] Ruby App Structure

**Location**: `~/git/sushi/master/lib/YourAppApp.rb`

```ruby
#!/usr/bin/env ruby
# encoding: utf-8

require 'sushi_fabric'
require_relative 'global_variables'
include GlobalVariables

class YourAppApp < SushiFabric::SushiApp
  def initialize
    super
    @name = 'YourApp'
    @params['process_mode'] = 'DATASET'  # or 'SAMPLE'
    @analysis_category = 'Category'       # e.g., 'SingleCell', 'QC'
    @description =<<-EOS
Brief description of what your app does.<br/>
    EOS
    @required_columns = ['Name', 'InputColumn']
    @required_params = ['name']

    # Computational resources
    @params['cores'] = '8'
    @params['ram'] = '30'
    @params['scratch'] = '100'
    @params['name'] = 'YourApp_Result'
    @params['mail'] = ""

    # Environment modules
    @modules = ["Dev/R"]

    # Inherited tags/columns
    @inherit_tags = ["Factor", "B-Fabric"]
  end

  def next_dataset
    report_dir = File.join(@result_dir, @params['name'])
    {
      'Name' => @params['name'],
      'Report [Link]' => File.join(report_dir, '00index.html'),
      'Species' => (dataset = @dataset.first and dataset['Species'])
    }
  end

  def commands
    run_RApp("EzAppYourApp")
  end
end
```

### Execution Modes

| Mode | Description |
|------|-------------|
| `SAMPLE` | One job per sample row |
| `DATASET` | One job for entire dataset |
| `BATCH` | Batch processing mode |

---

## [DEV-040] Rmd Templates

**Location**: `~/git/ezRun/inst/templates/YourApp.Rmd`

### YAML Header (Required Format)

```yaml
---
title: "`r if (exists('reportTitle')) reportTitle else 'SUSHI Report'`"
output:
  html_document:
    mathjax: https://fgcz-gstore.uzh.ch/reference/mathjax.js
    self_contained: true
    includes:
      in_header: !expr system.file("templates/fgcz_header.html", package="ezRun")
    css: !expr system.file("templates/fgcz.css", package="ezRun")
editor_options:
  chunk_output_type: inline
---
```

### Standard Structure

```markdown
```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE, message = FALSE, warning = FALSE)
ezLoadPackage('DT')
ezLoadPackage('ggplot2')
output_dir <- "Outputs/"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
```

# {.tabset}

## Overview
Started on `r format(Sys.time(), "%Y-%m-%d %H:%M:%S")`

## Results {.tabset}

### Section 1
Content here

### Section 2
Content here

## Session Info
```{r session info}
ezSessionInfo()
```
```

---

## [DEV-050] Parameter Passing

### Ruby App Parameters

```ruby
# In YourAppApp.rb
@params['myParameter'] = 'default_value'
@params['myNumber'] = '10'  # Always strings in Ruby
@params['myChoice'] = ['option1', 'option2']  # Dropdown
@params['myMultiSelect', 'multi_selection'] = true
```

### R Method Access

```r
# In ezMethodYourApp
ezMethodYourApp <- function(input, output, param) {
  myValue <- param$myParameter
  myNum <- as.integer(param$myNumber)  # Convert string to number
  myChoice <- param$myChoice

  # Input metadata access
  dataset <- input$meta
  sampleNames <- rownames(dataset)
  inputPaths <- input$getFullPaths("ColumnName")
}
```

### Type Conversion Reference

| Ruby Type | R Access | Conversion |
|-----------|----------|------------|
| String | `param$name` | None |
| Number | `as.integer(param$cores)` | `as.integer()` or `as.numeric()` |
| Boolean | `param$flag == "true"` | String comparison |
| Array | `param$list` | Auto-converted to R vector |

---

## [DEV-060] Coding Style

### Naming Conventions

| Type | Style | Example |
|------|-------|---------|
| Variables | camelCase | `sampleName`, `nReads`, `geneNames` |
| Functions | underscore_separated | `process_samples()`, `calculate_mean()` |

### Mandatory Rules

```r
# ALWAYS use curly braces
if (condition) {
  do_something()
}

# Use library, not require (or ezLoadPackage)
library(dplyr)
ezLoadPackage('dplyr')

# Safe iteration
for (i in seq_along(x)) { ... }  # NOT 1:length(x)

# Use column names, not indices
data[, "gene_name"]  # NOT data[, 3]

# All function inputs as parameters
my_function <- function(input_value) {
  result <- input_value * 2
  return(result)
}
```

---

## [CLI-010] sushi_fabric Command

### Basic Usage

```bash
cd /srv/sushi/production/master
bundle exec sushi_fabric --class AppName --dataset /path/to/dataset.tsv --project 1535 [options]
```

### Command Options

| Option | Description | Default |
|--------|-------------|---------|
| `-c, --class CLASS` | SushiApp class name (required) | - |
| `-d, --dataset FILE` | Path to DataSet TSV file | - |
| `-i, --dataset_id ID` | DataSet ID from SUSHI database | - |
| `-r, --run` | Execute job (without: test mode) | test mode |
| `-p, --project NUM` | Project number | 1001 |
| `-u, --user USER` | Submit user | sushi_lover |
| `-n, --next_dataset_name NAME` | Output dataset name | Auto-generated |
| `-m, --parameterset FILE` | Parameter TSV file | App defaults |
| `-f, --off_bfab` | Disable B-Fabric registration | false |

### Example: Submit FastQC Job

```bash
cd /srv/sushi/production/master

bundle exec sushi_fabric \
  --class FastqcApp \
  --run \
  --dataset /srv/gstore/projects/p1535/raw_data/dataset.tsv \
  --project 1535 \
  --dataset_name "RawData_FastQC"
```

---

## [CLI-020] Dataset TSV Format

### Basic Structure

```tsv
Name	Read1 [File]	Read2 [File]	Species	Condition [Factor]
Sample1	/path/sample1_R1.fastq.gz	/path/sample1_R2.fastq.gz	Homo_sapiens	Control
Sample2	/path/sample2_R1.fastq.gz	/path/sample2_R2.fastq.gz	Homo_sapiens	Treatment
```

### Column Type Suffixes

| Suffix | Meaning | Example |
|--------|---------|---------|
| `[File]` | Path to local file | `Read1 [File]` |
| `[Link]` | Web-accessible URL | `Report [Link]` |
| `[Factor]` | Experimental factor | `Condition [Factor]` |
| (none) | Plain metadata | `Species` |

---

## [CLI-030] Parameter TSV Format

### Basic Structure

```tsv
Parameter	Value
cores	8
ram	30
scratch	100
refBuild	Homo_sapiens/Ensembl/GRCh38.p14/Annotation/Release_112-2024-01-17
mail	user@fgcz.ethz.ch
```

### Common Parameters

| Parameter | Description | Example Values |
|-----------|-------------|----------------|
| `cores` | CPU cores per job | 4, 8, 16, 32 |
| `ram` | RAM in GB per core | 8, 16, 30, 60 |
| `scratch` | Scratch space in GB | 100, 500, 1000 |
| `refBuild` | Reference genome | Homo_sapiens/Ensembl/... |

---

## [DEPLOY-010] Test Instance Setup

### Step-by-Step

```bash
# 1. SSH to test server
ssh fgcz-h-083

# 2. Setup environment
source /usr/local/ngseq/etc/lmod_profile
module load Dev/Ruby/3.3.7
eval "$(/usr/local/ngseq/miniforge3/bin/conda shell.bash hook)"
conda activate gi_py3.12.8

# 3. Clone and setup
cd /srv/sushi
bash sushi_setup_script/setup_test_sushi_latest.sh

# 4. Start test server
cd [username]_test_sushi_*/master
BFABRICPY_CONFIG_ENV=TEST bundle exec rails s -e production -b fgcz-h-083.fgcz-net.unizh.ch -p 5000

# 5. Access via VPN: http://fgcz-h-083.fgcz-net.unizh.ch:5000
```

### Important Notes

- Uses local MySQL database on the test host
- Jobs submitted directly to SLURM via sbatch
- B-Fabric uses test environment (`BFABRICPY_CONFIG_ENV=TEST`)
- Dataset registration may fail if project doesn't exist in test B-Fabric

---

## [DEPLOY-020] Production Deployment

### Step-by-Step (fgcz-h-082)

```bash
# 1. Login as trxcopy
ssh fgcz-h-082
sudo -u trxcopy -i

# 2. Run setup script
cd /srv/sushi
bash sushi_setup_script/setup_prod_sushi_latest.sh

# 3. Backup current production
mv production production.bak.$(date +%Y%m%d)

# 4. Activate new version
mv trxc_prod_sushi_$(date +%Y%m%d) production

# 5. Restart Apache (as non-trxcopy user)
exit
sudo /etc/init.d/apache2 restart
```

### Verification Checklist

- [ ] Web access works at https://fgcz-sushi.uzh.ch
- [ ] Login works with LDAP credentials
- [ ] Projects are visible
- [ ] Job submission works
- [ ] Results are accessible

---

## [DEPLOY-030] Apache Configuration

### Configuration Files

| File | Purpose |
|------|---------|
| `/etc/apache2/sites-available/sushi.conf` | Virtual host configuration |
| `/etc/apache2/mods-available/passenger.conf` | Passenger module config |
| `/etc/apache2/mods-available/passenger.load` | Passenger module load |

### Production Virtual Host

```apache
<virtualhost *:8880>
   ServerName fgcz-sushi.uzh.ch
   DocumentRoot /srv/sushi/production/master/public
   <Directory /srv/sushi/production/master/public>
      Require all granted
   </Directory>
   ErrorLog ${APACHE_LOG_DIR}/sushi_prod_error.log
   CustomLog ${APACHE_LOG_DIR}/sushi_prod_access.log combined env=!from_proxy
   SetEnv SECRET_KEY_BASE prodsushi
</virtualhost>
Listen 8880
```

### Passenger Configuration

```apache
<IfModule mod_passenger.c>
  PassengerRoot /usr/local/ngseq/packages/Dev/Ruby/3.3.7/lib/ruby/gems/3.3.0/gems/passenger-6.0.25
  PassengerDefaultRuby /usr/local/ngseq/packages/Dev/Ruby/3.3.7/bin/ruby
  PassengerDefaultUser trxcopy
  PassengerMaxPoolSize 100
  PassengerMinInstances 20
  PassengerStartTimeout 300
</IfModule>
```

---

## [DB-010] MySQL Operations

### Connect to Database

```bash
sudo mysql -u root -p
```

### Useful Queries

```sql
-- Recent jobs with status
SELECT j.id, j.script_path, j.status, j.created_at, d.name as dataset
FROM jobs j
JOIN data_sets d ON j.data_set_id = d.id
ORDER BY j.created_at DESC
LIMIT 20;

-- Failed jobs in last 24 hours
SELECT j.id, j.script_path, j.stderr_path, j.created_at
FROM jobs j
WHERE j.status = 'failed'
AND j.created_at > DATE_SUB(NOW(), INTERVAL 24 HOUR);

-- Datasets by project
SELECT id, name, parent_id, bfabric_id, created_at
FROM data_sets
WHERE project_id = 1535
ORDER BY created_at DESC;
```

---

## [DB-020] Backup and Restore

### Backup Database

```bash
sudo mysqldump -u root -p --single-transaction --quick \
  --routines --events --triggers --hex-blob \
  --default-character-set=utf8mb4 --order-by-primary \
  --no-tablespaces --skip-comments --databases sushi \
  | gzip > sushi_db_$(date +%F).sql.gz
```

### Restore Database

```bash
gunzip -c sushi_db_2026-01-06.sql.gz | sudo mysql
```

### Backup Location

- Daily backups: `/srv/GT/software/dumps/SUSHI_Debian12/`
- Cron job runs at 7:30 AM daily

---

## [JOBMGR-010] Job Manager Architecture

### Database-Mediated Job Submission

```
SUSHI (Rails) → MySQL jobs table ← Job Manager (Python) → sbatch → SLURM
```

- **SUSHI**: Registers jobs in MySQL `jobs` table via ActiveJob (async)
- **Job Manager**: Python daemon polls `jobs` table, submits via `sbatch`
- **No direct messaging**: Uses shared database state (similar to gDaemon)
- **Repository**: https://gitlab.bfabric.org/Genomics/new_job_manager_2024/

### Job Status Values

| Status | Description |
|--------|-------------|
| `CREATED` | New job entered by SUSHI |
| `SUBMITTED` | Script found, submitted to SLURM |
| `PENDING` | SLURM pending |
| `RUNNING` | SLURM running |
| `COMPLETED` | SLURM completed |
| `FAILED` | SLURM failed |
| `SCRIPT_NOT_FOUND` | Job script not found (retry) |

---

## [JOBMGR-020] Job Manager Operations

### Check Running Job Managers

```bash
cat /misc/fgcz01/sushi/sushi_jobmanager_daemon.lock
```

### Start Job Manager

```bash
. /usr/local/ngseq/miniforge3/etc/profile.d/conda.sh
conda activate gi_sushi_jobmanager_2024
python start_sushi_jobmanager.py -b  # background mode
```

### View Logs

```bash
python tail_sushi_jobmanager_logs.py
# Or:
tail -f /misc/fgcz01/sushi/job_logs/sushi_job_manager-$(hostname).log
```

### Stop Job Manager

```bash
python stop_sushi_jobmanager.py
```

---

## [TROUBLE-010] Common Issues

| Issue | Likely Cause | Solution |
|-------|--------------|----------|
| Jobs stuck in pending | Job Manager down | Check/restart job manager |
| 500 errors on web | Ruby exception | Check `/var/log/apache2/error.log` |
| Dataset not found | Path mismatch | Verify gstore paths in dataset TSV |
| B-Fabric registration fails | Project mismatch | Check project exists in B-Fabric |
| Slow page loads | Database queries | Check slow query log |
| Job fails immediately | Missing modules | Check job stderr for module errors |

### Quick Health Check

```bash
# 1. Check Apache
sudo systemctl status apache2

# 2. Check MySQL
sudo systemctl status mariadb

# 3. Check Job Manager
ps aux | grep job_manager

# 4. Check disk space
df -h /srv/sushi /srv/gstore

# 5. Check SLURM
squeue -u trxcopy | head -20
```

---

## [TROUBLE-020] Log Files

| Log Type | Path | Purpose |
|----------|------|---------|
| **Rails Production** | `/srv/sushi/production/master/log/production.log` | Application logs |
| **Apache Error** | `/var/log/apache2/error.log` | Ruby script stdout/stderr |
| **Apache Access** | `/var/log/apache2/sushi_prod_access.log` | HTTP request logs |
| **Job Manager** | `/misc/fgcz01/sushi/job_logs/sushi_job_manager_fgcz-h-082.log` | Job submission logs |
| **MySQL Slow** | `/var/log/mysql/mariadb-slow-query.log` | Slow database queries |
| **Dataset Register** | `/srv/sushi/production/master/log/run_dataset_register_*.log` | B-Fabric registration |
| **gdaemon** | `~trxcopy/log/light.gdaemon.o` | gStore daemon logs |

### Quick Log Commands

```bash
# Recent Rails logs
tail -100 /srv/sushi/production/master/log/production.log

# Apache errors
sudo tail -100 /var/log/apache2/error.log

# Job manager logs
tail -100 /misc/fgcz01/sushi/job_logs/sushi_job_manager_fgcz-h-082.log
```

---

## [TROUBLE-030] Database Debugging

### Diagnosis Queries

```sql
-- Check job status
SELECT id, status, start_time, end_time FROM jobs ORDER BY id DESC LIMIT 10;

-- Orphaned jobs (no dataset)
SELECT j.* FROM jobs j
LEFT JOIN data_sets d ON j.data_set_id = d.id
WHERE d.id IS NULL;

-- Application usage (last 30 days)
SELECT sa.class_name, COUNT(*) as count
FROM jobs j
JOIN sushi_applications sa ON j.sushi_application_id = sa.id
WHERE j.created_at > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY sa.class_name
ORDER BY count DESC;
```

### Reset Stuck Jobs

```sql
-- Mark old pending jobs as failed
UPDATE jobs SET status='failed'
WHERE status='pending'
AND created_at < DATE_SUB(NOW(), INTERVAL 24 HOUR);
```

---

## [REF-010] Quick Reference

### Common Commands

```bash
# Environment setup
source /usr/local/ngseq/etc/lmod_profile
module load Dev/Ruby/3.3.7
eval "$(/usr/local/ngseq/miniforge3/bin/conda shell.bash hook)"
conda activate gi_py3.12.8

# Restart Apache
sudo /etc/init.d/apache2 restart

# Restart MySQL
sudo systemctl restart mariadb

# gStore operations
g-req copynow /path/file /srv/gstore/projects/pXXXXX/
g-req -w copy /path/file /srv/gstore/projects/pXXXXX/
gstore-list

# SLURM operations
squeue -u $USER
scancel <job_id>
sacct -j <job_id> --format=JobID,JobName,State,ExitCode
```

### Setup Scripts Location

```bash
/misc/fgcz01/sushi/sushi_setup_script/
├── setup_test_sushi_latest.sh      # Test instance
├── setup_prod_sushi_latest.sh      # Production
├── setup_demo_sushi_latest.sh      # Demo
└── setup_course1_sushi_latest.sh   # Course
```

### Key Git Repositories

| Repository | URL |
|------------|-----|
| SUSHI | https://github.com/uzh/sushi |
| ezRun | (internal FGCZ) |
| sushi_fabric | https://rubygems.org/gems/sushi_fabric/ |
| Setup Scripts | https://gitlab.bfabric.org/masaomi/sushi_setup_script |
| Job Manager | https://gitlab.bfabric.org/Genomics/new_job_manager_2024/ |

---

## MCP Server Integration Notes

This document is designed for efficient retrieval by MCP server tools:

1. **Section IDs**: Each section has a unique ID (e.g., `ARCH-010`, `DEV-020`) for precise retrieval
2. **Hierarchical Structure**: From overview to details, allowing progressive disclosure
3. **Self-contained Sections**: Each section can be retrieved independently
4. **Tables for Quick Reference**: Structured data for easy parsing
5. **Code Blocks**: Ready-to-use commands and templates

### Recommended MCP Tool Operations

| Task | Tool | Section |
|------|------|---------|
| Understanding architecture | `knowledge_get` | ARCH-010, ARCH-020 |
| Setting up test instance | `knowledge_get` | DEPLOY-010 |
| Creating new app | `knowledge_get` | DEV-010 to DEV-060 |
| CLI job submission | `knowledge_get` | CLI-010 to CLI-030 |
| Troubleshooting | `knowledge_get` | TROUBLE-* |
| Quick commands | `knowledge_get` | REF-010 |

---

**Document Version**: 1.0.0  
**Created**: 2026-01-06  
**Migrated to KairosChain L1**: 2026-01-20  
**Source Documents**:
- `paul-skills/Internal_Dev/SUSHI_documentation/sushi_installation_debian12.md`
- `paul-skills/Internal_Dev/SUSHI_documentation/sushi_wiki.md`
- `paul-skills/.claude/skills/fgcz-sushi-app-dev/SKILL.md`
- `paul-skills/.claude/skills/sushi-framework/SKILL.md` and references
