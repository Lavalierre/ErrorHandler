## Description
This script will override the default error handler, keeping the same message format, but providing you more information and possibilities.

Credits to https://gitlab.com/g2o/scripts/remoteerrortracker for the initial idea.

**Features:**
- Displaying client-side errors in the server console
- Automatic logging errors from both sides into separate files
- Protection from error spam - only one error of the same type per game session will be sent to the server (for example: if there's a ton of errors on the client-side, which are happened in the onRender event)
- Displaying level of local variables (level = 0 is getstackinfos() itself! level = 1 is the current function, level = 2 is the caller of the current function, and so on)

**Downsides:**
- No coloring in the server or in-game console (at least for now)
- In-game console will display client-side errors in the 'view info' mode, not 'view errors'

**Requirements:**
- BPackets (https://gitlab.com/bcore1/bpackets)

## Usage

- Copy all files into your server folder
- Import **meta.xml** in your config file
- (OPTIONAL) Change default file paths in the **main.nut**. They're placed on top of the file, in the **// SETTINGS //** comment section
