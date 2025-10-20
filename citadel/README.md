# Citadel AI Extension

This directory contains Citadel-specific extensions and customizations for Chatwoot.

## Structure

- `app/models/citadel/` - Model extensions that add Citadel-specific functionality to core models
- `app/models/` - Citadel-only models (Assistant, Community, etc.)
- `app/controllers/` - Citadel-specific controllers and controller extensions
- `app/services/` - Citadel-specific service objects
- `app/jobs/` - Citadel-specific background jobs
- `app/listeners/` - Citadel event listeners
- `config/initializers/` - Citadel-specific initializers
- `lib/` - Citadel-specific libraries and utilities

## How It Works

This directory follows Chatwoot's Enterprise Edition pattern, using the `prepend_mod_with` and `include_mod_with`
system to extend core functionality without modifying upstream files.

## Code Isolation Patterns

### Models, Controllers, Services, Jobs
- **Use `prepend_mod_with` or `include_mod_with`** to extend upstream classes
- Keep upstream files pristine by placing extensions in `citadel/app/`
- Example: `BulkActionsJob.prepend_mod_with('BulkActionsJob')` loads `citadel/app/jobs/citadel/bulk_actions_job.rb`

### Views
- Place override views in `citadel/app/views/` - they automatically take precedence
- Rails view path configured to check citadel views first

### Specs (Tests)
- **Minimal modifications to upstream specs are ACCEPTABLE and necessary**
- RSpec has no isolation mechanism - citadel code is ALWAYS loaded during tests
- Upstream specs test the ACTUAL integrated behavior (including citadel modifications)
- **New citadel-specific tests** go in `spec/citadel/` directory
- Example: If citadel adds Assistant to agents list, the upstream spec must expect `count + 1`

### Class Methods vs Instance Methods
- **Instance methods**: Use `Model.include_mod_with('Module')` or `Model.prepend_mod_with('Module')`
- **Class methods**: Use `Model.singleton_class.prepend_mod_with('Module::ClassName')`
- Prepending to singleton class makes instance methods in the module become class methods on the target
