## Description
This script will override the default error handler, keeping the same message format, but providing you more information and possibilities.

Credits to https://gitlab.com/g2o/scripts/remoteerrortracker for the initial idea.

## Features:
- Automatic logging errors from server side into separate file
- Displaying level of local variables (level = 0 is getstackinfos() itself! level = 1 is the current function, level = 2 is the caller of the current function, and so on)
- Ability to change level of displayable local variables
- Display name of the function, where error is occurred (**NOTE:** This is disabled by default, to enable it read section Usage)

## Additional features:
1. If [BPackets](https://gitlab.com/bcore1/bpackets) module is loaded on **both sides**:
- Automatic display client-side errors in the server console
- Logging errors from client-side into separate file, as well as server-side errors
- Protection from error spam - only one error of the same type per game session will be sent to the server (for example: if there's a ton of errors on the client-side, which are happened in the onRender event)
- Sending of client-side local variables information to the server (**NOTE:** This is disabled by default, to enable it read section Usage)
- Ability to send message from the client-side 'print' function to the server (as well as writing it alongside with client-side errors)

2. If [Regex](https://gitlab.com/thunderglow1453/Squirrel-Regex-Module) and [ANSIConsole](https://gitlab.com/g2o/modules/ansiconsole) modules are loaded on the **server-side**:
- Some parts of the error message will be colored

## Downsides:
- In-game console will display client-side errors in the 'view info' mode, not 'view errors'

## Usage

- Copy all files into your server folder
- Import **meta.xml** in your config file
  
(OPTIONAL) Change default settings, which are placed on top of the **main.nut** file, in the **// SETTINGS //** comment section:
- **s_serverFile** to the file name, where server-side errors will be logged
- **s_clientFile** to the file name, where client-side errors will be logged (if this additional feature is enabled)
- **b_printFunctionName** to display name of the function, where error is occurred
- **b_clientSideLocals** to send information about client-side local variables to the server (enabling this may cause some load on the network)
- **i_serverDepth** AND **i_clientDepth** to change the level of displayable local variables information (level = 0 is getstackinfos() itself! level = 1 is the current function, level = 2 is the caller of the current function, and so on)

### How to use send print message client -> server
```C++
// print(string text[, bool synchronize])
print("Client-Side Message", true);
```
