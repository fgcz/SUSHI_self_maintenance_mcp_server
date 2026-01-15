# SUSHI Skills DSL Definitions
# Pure Skills Design: Self-Referential, Evolvable, Auditable

# =============================================================================
# Core Safety Skill (Immutable)
# =============================================================================

skill :core_safety do
  version "1.0"
  title "Core Safety Rules"
  
  guarantees do
    immutable
    always_enforced
  end
  
  evolve do
    deny :guarantees
    deny :behavior
    deny :content
  end
  
  content <<~MD
    ## Core Safety Invariants
    
    These rules cannot be modified by self-evolution:
    
    1. Evolution must be explicitly enabled
    2. Human approval is required for changes (by default)
    3. All modifications create automatic snapshots
    4. Immutable skills cannot be altered
    5. Evolution count is limited per session
  MD
end

# =============================================================================
# Self-Inspection Skill (Read-Only Introspection)
# =============================================================================

skill :self_inspection do
  version "1.0"
  title "Self Inspection"
  use_when "LLM needs to understand the skill system itself"
  
  inputs :none
  
  guarantees do
    read_only
    no_side_effects
    explainable
  end
  
  behavior do
    Kairos.skills.map do |skill|
      {
        id: skill.id,
        version: skill.version,
        title: skill.title,
        guarantees: skill.guarantees,
        has_evolution_rules: !skill.evolution_rules.nil?
      }
    end
  end
end

# =============================================================================
# Architecture Skills
# =============================================================================

skill :arch_010 do
  version "1.0"
  title "System Architecture"
  use_when "Understanding component relationships"
  
  inputs :sushi_context
  
  guarantees do
    architecture_comprehension
    component_relationships
  end
  
  evolve do
    allow :content
    deny :guarantees
  end
  
  content <<~MD
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
    │ - gStore paths   │ │                  │ │                      │
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
  MD
end

skill :arch_020 do
  version "1.0"
  title "Data Flow"
  use_when "Tracing job execution flow"
  
  inputs :sushi_context
  depends_on :arch_010
  
  guarantees do
    flow_understanding
    traceable
  end
  
  evolve do
    allow :content
    deny :guarantees
  end
  
  content <<~MD
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
  MD
end

# =============================================================================
# Action History Skill (Read-Only)
# =============================================================================

skill :action_history do
  version "1.0"
  title "Action History Viewer"
  use_when "LLM needs to review what actions it has taken"
  
  inputs :limit
  
  guarantees do
    read_only
    no_side_effects
  end
  
  behavior do |input|
    limit = input[:limit] || 20
    Kairos.action_history(limit: limit)
  end
end
