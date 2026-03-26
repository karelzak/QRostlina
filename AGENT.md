# QRostlina (HortiLog) - Project Agent Context

This file serves as a persistent context for Gemini (or other AI agents) to understand the goals and state of the QRostlina project.

## Project Overview
QRostlina is a mobile application (Flutter/Android) for managing a plant inventory (primarily dahlia tubers) in a nursery. It supports field work, data sharing via Firebase, and durable label printing.

## Core Mandates
- **Language:** Use English for all code, comments, and commit messages.
- **Development Environment:** Linux (Fedora).
- **Target Platform:** Android.
- **Small Changes:** Commit often with descriptive messages in English.
- **UI/UX:** High-contrast design for sunlight, large controls for gloved hands.
- **Offline-first:** Local cache with Firebase synchronization.

## Technical Stack
- **Frontend:** Flutter (Dart)
- **Backend:** Firebase (Firestore, Auth)
- **Scanning:** QR code (S-, P-, B-, C- prefixes)
- **Printing:** Bluetooth (Brother TZe)
- **Export:** CSV/Excel

## Data Model (Unique IDs required)
- **Species (S-):** Variety name, Latin name, color, height, description, photo.
- **Plant Unit (P-):** Instance of a species, status (in ground, stock, sold), location.
- **Location:**
    - **Bed (B-):** Name, row/position.
    - **Crate (C-):** Type/ID.

## Scanning Logic
- **S-ID:** Open Species card, show instances, allow adding new P-ID.
- **P-ID:** Open Plant card, allow location/species change.
- **B-ID:** Show bed contents, allow moving to crates or adding new plants.
- **C-ID:** Show crate contents, allow moving to beds or adding new plants.

## Development Environment
- **OS:** Linux (Fedora)
- **Flutter SDK Path:** `/home/work/flutter/bin`
- **Project Path:** `/home/work/QRostlina`
- **Environment Note:** Flutter has been added to `~/.bashrc`. If the `flutter` command is not found in a new session, ensure `/home/work/flutter/bin` is in the `PATH`.

## MVP Scope (Phase 1)
1. [x] Infrastructure, directory structure, git initialization.
2. [x] Create AGENT.md (this file).
3. [x] Flutter application skeleton (Android & Linux).
4. [x] High-contrast UI theme (Yellow/Black).
5. [x] Data Models (Species, PlantUnit, Location).
6. [x] QR Scanner Service & Mock Scanner Screen.
7. [x] Mock Database Service & Species List Screen.
8. [ ] Android SDK setup (Command Line Tools preferred).
9. [ ] Script for Android deployment.
10. [ ] Firebase integration (Auth & Firestore).
11. [ ] Detailed Cards for Species (S-), Plants (P-), Beds (B-), Crates (C-).
12. [ ] CRUD implementation for all entities.
13. [ ] Bed/Crate content listing.

## Future Plans
- Logs for bed maintenance (fertilizing, care).
- AI (Gemini) integration for plant care consultation.
- Care planning and scheduling.
