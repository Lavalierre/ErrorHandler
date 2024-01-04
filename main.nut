// SETTINGS //

local s_serverFile = "errors/server.txt";
local s_clientFile = "errors/client.txt";

// *** //

ERROR_HANDLER <- -1;

// BPackets // 
class ClientErrorMessage extends BPacketMessage
{   
    </ type = BPacketString />
    error = null
    </ type = BPacketArray(BPacketTable({func = BPacketString, src = BPacketString, line = BPacketInt32})) />
    stack = null
}

if (SERVER_SIDE)
{
    ClientErrorMessage.bind(function(pid, message){

        local msg = ERROR_HANDLER.GenerateMessage(message.error, message.stack, null, pid);
        ERROR_HANDLER.Print(msg);
    });
}
// *** //

class CErrorHandler
{

    a_errorsCatched = [];

    constructor() {}

    function Write(fileName, message)
    {
        local date = date(time());

        local errorFile = file(fileName, "a+");
        errorFile.write(format("[%d-%02d-%02d %02d:%02d:%02d] ", date.year, date.month + 1, date.day, date.hour, date.min, date.sec));
        for (local i = 0; i < message.len(); i++)
            errorFile.write(message[i] + "\n");
        
        errorFile.close();
    }

    function GenerateMessage(error, stack, locals = null, pid = -1)
    {
        local message = [];

        message.push(format("[squirrel] Error runtime: '%s' (Ln: %d): %s\n", stack[0].src, stack[0].line, error));

        if (pid != -1)
            message.push(format("-== Received from player '%s' (ID: %d) ==-", getPlayerName(pid), pid));

        if (locals != null)
        {
            local type      = -1;
            local value     = -1;

            message.push("-== Local variable: ==-");

            for (local i = 0; i < locals.len(); i++)
            {
                foreach(key, val in locals[i])
                {
                    type = typeof val;
                    value = val;
                    
                    if (typeof val == "table" && val == getroottable())
                        value = "this";
                    
                    message.push(format("+ (Lv: %d) %s:", i, typeof val) + " " + value);
                }
            }
        }

        return message;
    }

    function Print(message)
    {
        for (local i = 0; i < message.len(); i++)
            print(message[i]);

        if (SERVER_SIDE)
        {
            if (message.len() > 2)
                Write(s_serverFile, message);
            else
                Write(s_clientFile, message);
        }
    }

    // Check for duplicates on the client-side
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

        if (CLIENT_SIDE && ERROR_HANDLER.CatchError(stack))
            sync = true;
        
		stackInfos.push(stack);
        stackLocals.push(stackInfo.locals);
	}

    local printMessage = ERROR_HANDLER.GenerateMessage(error, stackInfos, stackLocals);
    ERROR_HANDLER.Print(printMessage);

    if (CLIENT_SIDE && sync && stackInfos.len() != 0)
    {
        local syncMessage = ClientErrorMessage(error, stackInfos);
        syncMessage.serialize().send(RELIABLE);
    }

}

ERROR_HANDLER = CErrorHandler();
seterrorhandler(ErrorHandler);