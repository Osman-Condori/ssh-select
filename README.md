# sshi

A lightweight, native Lua TUI manager for SSH configurations[cite: 1, 2].

## Description

**sshi** is a terminal-based utility designed for system administrators and developers who manage multiple remote servers[cite: 1]. Built with modularity and performance in mind, it transforms your plain-text `~/.ssh/config` file into an interactive and secure Text User Interface (TUI) control panel, running directly in your console with an insignificant resource footprint[cite: 1, 2].

## Features

* **Native Configuration Parsing:** Directly reads, processes, and updates the standard `~/.ssh/config` file without proprietary databases or hidden formats[cite: 1, 2].
* **Keyboard-Centric TUI:** Fast navigation using arrow keys or native Unix motions (`HJKL`) powered by `lcurses`[cite: 1, 2].
* **Integrated Fuzzy Finder:** Instantly filter through dozens of hosts by typing any part of the name, alias, or IP address[cite: 1].
* **Dynamic Tag System:** Organize your infrastructure using custom labels (e.g., `#production`, `#debian`, `#database`) directly within the search bar[cite: 1].
* **SSH Key Management:** Streamline workflows by auto-discovering local keys (`IdentityFile`), generating secure keys (like Ed25519), and injecting public keys into remote servers via an integrated `ssh-copy-id` shortcut[cite: 1].
* **TUI Form Assistant:** Complete CRUD operations (Add, Edit, Delete) to easily configure advanced parameters like `LocalForward` or `ProxyJump`[cite: 1].
* **Debian Friendly:** Tailored from the ground up to comply with upstream development standards and distribution packaging guidelines.

## Architecture Plan

The project is structured into three independent Lua modules to ensure clean code and easy auditing[cite: 1]:

1. **The Parser (Text Engine):** Handles reading `~/.ssh/config` syntax into clean Lua tables and writing changes back safely[cite: 1].
2. **The Search Engine:** Manages real-time fuzzy finding and dynamic tag matching filters[cite: 1].
3. **The TUI (Interface Layer):** Handles rendering menus, inputs, and interactive components using `lcurses` bindings[cite: 1, 2].

## Dependencies

To run or build `sshi`, you will need:

* **Lua** (5.3 or higher recommended)
* **lua-curses** (`lcurses` bindings)[cite: 2]

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
