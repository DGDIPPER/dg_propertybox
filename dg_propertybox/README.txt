PropertyBox — PIN Police Property Stash (No SQL)

PropertyBox is a FiveM script that allows police to store a suspect’s belongings using a 4-digit PIN and lets suspects retrieve their items later from a public pickup counter. It is built for QBX using ox_inventory, ox_target, and ox_lib, with JSON file persistence for property stashes. No SQL is required for PropertyBox storage.

Features

Police-only property deposit access

4-digit PIN based stash system

Public pickup using PIN

ox_target interaction zones

ox_inventory stash backend

JSON persistence (no SQL required for property stashes)

Automatic PIN cleanup when stash is empty

Manual police PIN clear command

Configurable locations and stash settings

How It Works

Police go to the configured property deposit location and use third-eye interaction to deposit property. They enter a 4-digit PIN, which opens a stash linked to that PIN. Police place the suspect’s items inside. When the stash is closed, the contents are saved to a JSON file.

The suspect later goes to the property pickup location, uses third-eye interaction, and enters the same 4-digit PIN. The stash opens and they can remove their items.

When a stash becomes empty, the PIN is automatically cleared and can be reused. Police can also manually clear a PIN with:


ox_lib

ox_inventory

ox_target

qbx_core

