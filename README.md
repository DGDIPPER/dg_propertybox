# dg_propertybox

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Framework](https://img.shields.io/badge/framework-FiveM-black)
![Inventory](https://img.shields.io/badge/inventory-ox_inventory-green)
![UI](https://img.shields.io/badge/ui-ox_lib-purple)
![Target](https://img.shields.io/badge/target-ox_target-orange)
![Storage](https://img.shields.io/badge/storage-JSON-lightgrey)
![Support](https://img.shields.io/badge/support-Discord-5865F2)

**PropertyBox** is a FiveM script where police store a suspect’s items in a **4-digit PIN stash** and the suspect retrieves them later at a pickup counter.  
Built with **ox_inventory**, **ox_target**, and **ox_lib**. Uses **JSON file persistence — no SQL required.**

---

## 🎬 Video Showcase
https://www.youtube.com/watch?v=nBdecSpdfTk

---

## ✨ Features

- 🔐 4-digit PIN based property stash
- 👮 Police can deposit suspect items
- 📦 Suspects retrieve items later using PIN
- 🧾 JSON file persistence (no database needed)
- 🎯 ox_target interaction zones
- 🖥️ ox_lib UI dialogs & menus
- 📦 ox_inventory stash system
- ⚡ Lightweight & optimized
- 🔄 Survives server restarts

---

## ✅ Requirements

- ox_inventory  
- ox_lib  
- ox_target  

Make sure all dependencies are updated.

---

## 📦 Installation

1. Download `dg_propertybox`
2. Place into your `resources` folder
3. Ensure correct start order:

```cfg
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure dg_propertybox
