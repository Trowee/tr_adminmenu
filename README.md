# TR AdminMenu

A clean, modern, and optimized admin menu for FiveM, fully compatible with ESX, QBCore, and QBox frameworks. Built for speed, reliability, and ease of use, making server administration simpler than ever.

## Features
- **Multi-Framework Support:** ESX, QBCore, QBox.
- **Inventory Integration:** Supports `ox_inventory`, `qb-inventory`, `qs-inventory`, and `core_inventory`.
- **Advanced Spectate System:** Smooth spectating, prevents getting stuck or falling under the map.
- **Offline Actions:** Manage offline players (warn, ban, set job, set group, inventory management).
- **Discord Logs:** Built-in webhooks for almost every action.
- **Duty System:** Track admin duty time and performance (analytics).
- **Extensive Configuration:** Permissions can be assigned per group or via Steam Hex override.

## Installation

1. Download the resource and place it in your `resources` folder.
2. Rename the folder to `tr_adminmenu` (if it isn't already).
3. Import `tr_adminmenu.sql` into your database.
4. Ensure you have the required dependencies:
   - `oxmysql`
   - `ox_lib`
   - Your framework (`es_extended`, `qb-core`, or `qbx_core`)
5. Add `ensure tr_adminmenu` to your `server.cfg`.
6. Configure `shared/config.lua` and `shared/webhooks.lua` to your liking.

## Dependencies
- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_lib](https://github.com/overextended/ox_lib)

## Commands
- `/amenu` - Opens the main Admin Panel (Default Keybind: DELETE)
- `/tr_adminmenu_quick` - Opens the quick action menu (Default Keybind: F10)
