# Sound Effects

Place your sound effect files in this directory. The game will automatically detect and use them if they exist.

## Required Sound Files

The game looks for the following sound files (in order of preference):

1. **click.wav** or **click.ogg** - Played when the player moves
2. **eat.wav** or **eat.ogg** - Played when the player collects food
3. **convert.wav** or **convert.ogg** - Played when fat auto-converts to glucose
4. **death.wav** or **death.ogg** - Played when the player dies (touches an enemy)

## Format

- Supported formats: `.wav` or `.ogg`
- The game will first try to load `.wav` files, then fall back to `.ogg` if not found
- If no sound file is found, the game will simply not play that sound (no error)

## Testing Without Sounds

The game is designed to work perfectly fine without any sound files. This allows you to:
1. Test the game first
2. Find/create appropriate sound effects later
3. Add them to this folder when ready

The sounds will automatically start working once the files are in place - no code changes needed!
