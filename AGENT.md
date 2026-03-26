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

## MVP Scope (Phase 1)
1. [x] Infrastructure, directory structure, git initialization.
2. [x] Create AGENT.md (this file).
3. [ ] Flutter application skeleton.
4. [ ] Emulator/Native Linux support setup.
5. [ ] Script for Android deployment.
6. [ ] Firebase integration (Auth & Firestore).
7. [ ] CRUD for Species and Plants.
8. [ ] QR scanner implementation.
9. [ ] Bed content listing.

## Future Plans
- Logs for bed maintenance (fertilizing, care).
- AI (Gemini) integration for plant care consultation.
- Care planning and scheduling.
