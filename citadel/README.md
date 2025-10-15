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
