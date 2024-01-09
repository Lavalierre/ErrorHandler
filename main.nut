// SETTINGS //

local s_serverFile          = "server_errors.txt";
local s_clientFile          = "client_errors.txt";
local b_clientSideLocals    = false;
local b_printFunctionName   = false;

// *** //
local BPACKET_LOADED    = "BPacketMessage" in getroottable();
local REGEX_LOADED      = "Regex" in getroottable();

local COLOR_GREEN       = "\x1b[32m";
local COLOR_YELLOW      = "\x1b[33m";
local COLOR_WHITE       = "\x1b[37m";


ERROR_HANDLER <- -1;

// BPackets // 
if (BPACKET_LOADED)
{
    class ClientErrorMessage extends BPacketMessage
    {   
        </ type = BPacketString />
        error = null
        </ type = BPacketArray(BPacketTable({func = BPacketString, src = BPacketString, line = BPacketInt32})) />
        stack = null
        </ type = BPacketString />
        locals = null
    }

    class ClientPrintMessage extends BPacketMessage
    {
        </ type = BPacketString />
        message = null
    }

    if (SERVER_SIDE)
    {
        ClientErrorMessage.bind(function(pid, message){

            local msg = ERROR_HANDLER.GenerateMessage(message.error, message.stack, null, pid);
            msg = ERROR_HANDLER.DeserializeLocals(message.locals, msg);
            ERROR_HANDLER.Print(msg);
        });

        ClientPrintMessage.bind(function(pid, message){
            local name  = isPlayerConnected(pid) ? getPlayerName(pid) : "unknown";
            local msg   = null;

            if (REGEX_LOADED)
                msg = format("\x1b[33m[squirrel]\x1b[37m '%s' (ID: %d): %s", name, pid, message.message);
            else
                msg = format("[squirrel] '%s' (ID: %d): %s", name, pid, message.message);

            ERROR_HANDLER.Print([pid, msg]);
        });
    }

    if (CLIENT_SIDE)
    {
        local __print = print;
        function print(text, sync = false)
        {
            __print(text);
            if (sync)
                ClientPrintMessage(text).serialize().send(RELIABLE);
        }
    }
}
// *** //

class CErrorHandler
{

    a_errorsCatched = [];

    constructor() {}

    // Printing & Writing messages //
    function GenerateMessage(error, stack, locals = null, pid = -1)
    {
        local message = [];

        local funcName = b_printFunctionName ? format("Func: %s, ", stack[0].func) : "";
        
        message.push(pid);

        if (SERVER_SIDE && REGEX_LOADED)
            message.push(format("%s[squirrel]%s Error runtime: '%s' (%sLn: %d): %s", COLOR_YELLOW, COLOR_WHITE, stack[0].src, funcName, stack[0].line, error));
        else
            message.push(format("[squirrel] Error runtime: '%s' (%sLn: %d): %s", stack[0].src, funcName, stack[0].line, error));

        if (pid != -1)
        {
            local name = "unknown";
            if (isPlayerConnected(pid))
                name = getPlayerName(pid);

            message.push(format("-== Received from player %s'%s'%s (ID: %d) ==-", COLOR_GREEN, name, COLOR_WHITE, pid));
        }

        if (locals != null)
        {
            local type      = -1;
            local value     = -1;

            message.push("\n-== Local variable: ==-");

            for (local i = 0; i < locals.len(); i++)
            {
                foreach(key, val in locals[i])
                {
                    type = typeof val;
                    value = val;
                    
                    if (typeof val == "table" && val == getroottable())
                        value = "this";
                    
                    if (SERVER_SIDE && REGEX_LOADED)
                        message.push(format("%s+%s (Lv: %d) %s:", COLOR_GREEN, COLOR_WHITE, i, typeof val) + " " + value);
                    else
                        message.push(format("+ (Lv: %d) %s:", i, typeof val) + " " + value);
                }
            }
        }

        return message;
    }

    function Print(message)
    {
        for (local i = 1; i < message.len(); i++)
            print(message[i]);

        if (SERVER_SIDE)
        {
            if (message[0] == -1)
                Write(s_serverFile, message);
            else
                Write(s_clientFile, message);
        }
    }

    function Write(fileName, message)
    {
        local date = date(time());
        message = RemoveANSICodes(message);

        local errorFile = file(fileName, "a+");
        errorFile.write(format("[%d-%02d-%02d %02d:%02d:%02d] ", date.year, date.month + 1, date.day, date.hour, date.min, date.sec));
        for (local i = 1; i < message.len(); i++)
            errorFile.write(message[i] + "\n");
        
        errorFile.close();
    }

    function RemoveANSICodes(message)
    {
        if (REGEX_LOADED)
        {
            local reg       = Regex(@"\x1b.*?m");
            local outstr    = "";
            local lastidx   = 0;
            local results   = null;

            for (local i = 1; i < message.len(); i++)
            {
                outstr  = "";
                lastidx = 0;
                results = reg.capture(message[i]);
                
                if (results != null)
                {
                    foreach(j, val in results)
                    {
                        outstr += message[i].slice(lastidx, val.begin);
                        lastidx = val.end;
                    }

                    outstr += message[i].slice(lastidx, message[i].len());
                    message[i] = outstr;
                }
            }
        }

        return message;
    }
    // *** //

    // Sending client-side locals //
    function SerializeLocals(locals)
    {
        local message = "";

        if (locals != null)
        {
            local type      = -1;
            local value     = -1;

            message += "\n-== Local variable: ==-\r";

            for (local i = 0; i < locals.len(); i++)
            {
                foreach(key, val in locals[i])
                {
                    type = typeof val;
                    value = val;
                    
                    if (typeof val == "table" && val == getroottable())
                        value = "this";
                    
                    message += "%s+%s " + format("(Lv: %d) %s:", i, typeof val) + " " + value + "\r";
                }
            }
        }

        return message;
    }

    function DeserializeLocals(locals, message)
    {
        
        local splitLocals = split(locals, "\r", true);
        if (splitLocals != null)
        {
            for (local i = 0; i < splitLocals.len(); i++)
            {
                if (splitLocals[i].find("(Lv:") != null)
                    message.push(format(splitLocals[i], COLOR_GREEN, COLOR_WHITE));
                else
                    message.push(splitLocals[i]);
            }
        }

        return message;
    }
    // *** //

    // Check for duplicates on the client-side //
    function CatchError(stack)
    {
        for (local i = 0; i < a_errorsCatched.len(); i++)
        {
            if (stack.line  == a_errorsCatched[i].line && 
                stack.src   == a_errorsCatched[i].src)
                return false;
        }

        a_errorsCatched.push(stack);
        return true;
    }
    // *** //
}

function ErrorHandler(error)
{
    local depth = 2;
	local stackInfos = [];
    local stackLocals = [];
    local sync = false;

	while(true)
	{
		local stackInfo = getstackinfos(depth++)
		if (stackInfo == null) break
        
        local stack = {
            func = stackInfo.func ? stackInfo.func : "unknown_function",
            src =  stackInfo.src ? stackInfo.src : "unknown_source_file",
            line = stackInfo.line,
        };

        if (CLIENT_SIDE && !sync)
            if (ERROR_HANDLER.CatchError(stack))
                sync = true;
        
		stackInfos.push(stack);
        stackLocals.push(stackInfo.locals);
	}

    local printMessage = ERROR_HANDLER.GenerateMessage(error, stackInfos, stackLocals);
    ERROR_HANDLER.Print(printMessage);

    if (BPACKET_LOADED && CLIENT_SIDE && sync && stackInfos.len() != 0)
    {
        local locals = b_clientSideLocals ? ERROR_HANDLER.SerializeLocals(stackLocals) : "";
        local syncMessage = ClientErrorMessage(error, stackInfos, locals);
        syncMessage.serialize().send(RELIABLE);
    }

}

ERROR_HANDLER = CErrorHandler();
seterrorhandler(ErrorHandler);