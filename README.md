# TR AdminMenu

A clean, modern, and optimized admin menu for FiveM, fully compatible with ESX, QBCore, and QBox frameworks. Built for speed, reliability, and ease of use, making server administration simpler than ever.

## Features
<img width="3029" height="1826" alt="Screenshot 2026-09-30 223116" src="https://github.com/user-attachments/assets/c7225a65-e3dd-4da5-9fee-90f9071b6161" />
<img width="3053" height="1832" alt="Screenshot 2026-09-30 223123" src="https://github.com/user-attachments/assets/7f33aaf2-89a0-42ca-aff3-a8847df69fe8" />
<img width="3031" height="1826" alt="Screenshot 2026-09-30 223133" src="https://github.com/user-attachments/assets/29f7f66d-35bc-4c95-a001-2c3794f93f73" />
<img width="3039" height="1831" alt="Screenshot 2026-09-30 223148" src="https://github.com/user-attachments/assets/7ed60dde-2c9f-489e-84bc-f27559b0fcf9" />
<img width="698" height="1103" alt="Screenshot 2026-09-30 223203" src="https://github.com/user-attachments/assets/c4b98187-1f78-4281-b813-ecf045c26a49" />
<img width="3034" height="1836" alt="Screenshot 2026-09-30 222951" src="https://github.com/user-attachments/assets/f8e03866-f893-4c9a-9948-97d55ebac5eb" />
<img width="3032" height="1826" alt="Screenshot 2026-09-30 222957" src="https://github.com/user-attachments/assets/3cc4a53d-022b-46bd-ab60-adef1b3ad6e3" />
<img width="3030" height="1827" alt="Screenshot 2026-09-30 223002" src="https://github.com/user-attachments/assets/39f03bd2-ffaa-4b42-8991-c9f73791f03b" />
<img width="3029" height="1828" alt="Screenshot 2026-09-30 223008" src="https://github.com/user-attachments/assets/dbbf395f-c018-4ac5-acc6-a5652f537c85" />
<img width="3026" height="1813" alt="Screenshot 2026-09-30 223027" src="https://github.com/user-attachments/assets/982f4b14-482b-4174-ad6c-df56f492c018" />
<img width="3022" height="1822" alt="Screenshot 2026-09-30 223039" src="https://github.com/user-attachments/assets/5bf4bfe9-a594-4396-bbdb-135e97a1162b" />
<img width="3027" height="1830" alt="Screenshot 2026-09-30 223044" src="https://github.com/user-attachments/assets/5df9bf93-250d-46d4-a7a7-39304f5b3b86" />
<img width="3035" height="1824" alt="Screenshot 2026-09-30 223049" src="https://github.com/user-attachments/assets/650c9bce-3de9-4c45-ae96-29cec8e0c15a" />
<img width="3036" height="1830" alt="Screenshot 2026-09-30 223059" src="https://github.com/user-attachments/assets/a44b71a9-45f7-4dff-93f1-9e8497a6eeae" />

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
