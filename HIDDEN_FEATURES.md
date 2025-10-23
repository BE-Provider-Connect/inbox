# Temporarily Hidden Features

This document tracks features that have been hidden from the UI but remain functional in the codebase.

## Navigation Items Hidden

### Sidebar (`app/javascript/dashboard/components-next/sidebar/Sidebar.vue:513-524`)
- **Reports** - Entire Reports section with all sub-items
- **Campaigns** - Entire Campaigns section (Live chat, SMS, WhatsApp)
- **Settings > Agent Bots** - Bot management settings page

### Inbox Settings (`app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue:173-184`)
- **Bot Configuration Tab** - Per-inbox bot configuration settings

## Notes
- All backend functionality remains intact
- Features are still accessible via direct URL navigation
- Routes and APIs are not disabled
- Changes are marked with `// Citadel:` comments for easy identification during upstream merges
