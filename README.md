# Motanic - Game Prototype

A one-button morse code game based on the historical Titanic disaster, featuring procedurally generated content and strict black-and-white aesthetics.

## 🎮 Game Concept

You are the radio operator on the Titanic, desperately sending SOS signals to nearby ships. Using only the spacebar, tap out morse code messages while managing limited battery power. Your goal: survive until rescue ships arrive.

## 🎯 Prototype Requirements

### ✅ Mechanic: One-button controls
- **SPACE**: Tap for dot (.), hold for dash (-)
- **BACKSPACE**: Undo last input
- **Triple-tap dots**: Quick undo feature
- All core gameplay uses only one button

### ✅ World: Procedurally generated
- **Dynamic Messages**: SOS, CQD, coordinates, and distress calls
- **Random Elements**: 
  - Ship positions and arrival times
  - Iceberg placement and movement
  - Interference patterns
  - Titanic coordinates with realistic variance

### ✅ Aesthetic: Black and white
- Pure monochrome design
- Gray scales for depth and clarity
- No color elements except UI states
- Minimalist visual approach

### ✅ Wildcard: Historical event
- Based on the 1912 Titanic disaster
- Authentic morse code usage (SOS/CQD signals)
- Historical ship names (Carpathia, Californian, Olympic)
- Realistic coordinates near the actual sinking location

## 🎨 Visual Design

### Split-Screen Layout
- **Top Half**: Morse code interface with interference effects
- **Bottom Half**: Top-down ocean view with fog of war

### Visual Feedback Systems
1. **Signal Strength Visualization**: Expanding view radius based on accuracy
2. **Morse Code Highlighting**: Real-time feedback showing correct/incorrect inputs
3. **Atmospheric Effects**: Static noise, scan lines, and interference
4. **Dynamic Fog of War**: Vision expands with successful transmissions

## Core Mechanics

### Morse Code System
- Visual feedback for each dot and dash
- Color-coded accuracy display
- Progressive difficulty through longer messages

### Resource Management
- **Battery**: Depletes with each signal, restored after successful messages
- **Time**: Limited time per message, increases pressure

### Progression System
- Messages become more urgent over time
- Rescue ships approach based on signal quality
- View radius expands with success

## 📁 Project Structure

```
├── main.lua          # Entry point
├── game.lua          # Core game logic and state
├── visual.lua        # Rendering and visual effects
├── morse.lua         # Morse code dictionary and generation
├── input.lua         # Input handling and audio
└── beep.wav          # Morse code sound effect
```

## 🎯 Key Features for Demo

1. **Procedural Generation**: Every playthrough is unique
2. **Historical Authenticity**: Real morse code, ship names, and coordinates
3. **Emergent Narrative**: Message urgency increases over time
4. **Risk/Reward**: Accuracy vs. speed tension
5. **Atmospheric Design**: Minimalist aesthetics enhance tension
