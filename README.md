# CCPL-MentalGame

A 2D anime-style mental health game prototype built with Godot 4.

## 🌟 Overview

CCPL-MentalGame is an interactive educational and therapeutic game designed to help players understand and manage common psychological stressors through immersive gameplay and AI-enhanced interactions.

## 🎮 Key Features

- **Dynamic Maze Exploration**: Navigate through procedurally generated mazes representing internal psychological states.
- **Cognitive Card Battles**: Use cards based on psychological concepts to overcome "Cognitive Distortions."
- **AI-Powered Experiences**:
  - **Gemini Integration**: Generates dynamic background art based on the current game scenario.
  - **Voice Analysis**: Uses machine learning to classify emotional states and guide gameplay.
- **Interactive Storytelling**: Scenario-based challenges including Academic Pressure, Family Conflict, and Social Anxiety.

## 🛠️ Tech Stack

- **Game Engine**: [Godot Engine 4.x](https://godotengine.org/)
- **AI Services**: Google Gemini API
- **Audio Processing**: Custom voice classification service
- **Language**: GDScript

## 🚀 Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Exekiel179/ccpl-mentalgame.git
   ```
2. **Setup Credentials**:
   - Create a `.env` file in the project root.
   - Add your Gemini API credentials:
     ```env
     GEMINI_API_KEY=your_api_key_here
     GEMINI_API_ENDPOINT=https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent
     ```
3. **Open with Godot**:
   - Import `project.godot` into the Godot Engine 4.x editor.
   - Press F5 to run the project.

## 📄 License

Check the project files for specific licensing information.
