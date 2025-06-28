# LFG Arena Tool

An advanced World of Warcraft addon for finding and messaging arena players efficiently.

## Features

- **Player Parsing**: Parse player data directly from PvP leaderboards
- **Automated Whispers**: Send personalized whispers to multiple players with throttling
- **Smart Management**: Track whispered players and optionally remove them from lists
- **Tabbed Interface**: Easy-to-use interface with multiple tabs for different functions
- **Website Integration**: Direct link to PvP leaderboard for finding players

## Commands

- `/lfg` - Opens the main interface
- `/lfg w` - Starts whispering players from your list

## How to Use

1. **Finding Players**:
   - Visit [PvP Leaderboard](https://www.pvpleaderboard.com/leaderboards/filter?leaderboard=3v3&region=US)
   - Copy player data lines from the leaderboard

2. **Adding Players**:
   - Type `/lfg` to open the interface
   - Go to the "Add Players" tab
   - Paste the copied data into the text box
   - Click "Parse Players" to add them to your list

3. **Managing Your List**:
   - Switch to the "Player List" tab to see all players
   - Enable "Remove players after whispering" to auto-clean your list
   - Remove individual players with the "Remove" button
   - Clear the entire list with "Clear List"

4. **Sending Whispers**:
   - Use `/lfg w` to start whispering all players
   - There's a 1.5-second delay between whispers to avoid spam detection
   - Progress is shown in chat

## Data Format

The addon parses lines in this format:
```
13 2853 Envyion Sargeras Alliance Night Elf Female Priest Shadow dgb 130 - 55 70.3%
```

It extracts the player name (3rd field) and realm (4th field) to create entries like `Rudar-Sargeras`.

## Configuration

- **Whisper Message**: Customizable message sent to players
- **Remove After Whisper**: Option to automatically remove players after whispering
- **Player Tracking**: Keeps track of who has been whispered

## Installation

1. Extract the addon to your `Interface/AddOns/` folder
2. Restart World of Warcraft or reload UI (`/reload`)
3. Enable the addon in the AddOns menu

## Version History

- **2.0.0**: Complete rewrite with tabbed interface and advanced features
- **1.0.0**: Basic whisper functionality
Feel free to contribute by submitting issues or pull requests on the GitHub repository.

## License
This addon is open-source and available for anyone to use and modify.