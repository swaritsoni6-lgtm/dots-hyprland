import QtQuick
import qs.modules.common
import qs.modules.common.functions as CF

ApiStrategy {
    readonly property string apiKeyEnvVarName: "API_KEY"

    function buildEndpoint(model: AiModel): string {
        return "antigravity://localhost";
    }

    function reset() {
        // Reset strategy state
    }

    function onRequestFinished(message) {
        return { "finished": true };
    }

    function buildScriptFileSetup(filePath: string): string {
        return "";
    }

    function buildRequestData(model: AiModel, messages, systemPrompt: string, temperature: real, tools: list<var>, filePath: string) {
        let lastUserMessage = "";
        for (let i = messages.length - 1; i >= 0; i--) {
            if (messages[i].role === "user") {
                lastUserMessage = messages[i].rawContent;
                break;
            }
        }
        return {
            "prompt": lastUserMessage,
            "model": model ? model.model : "",
            "mode": Ai.currentMode || "",
            "conversationId": Ai.activeConversationId || "",
            "isContinue": messages.length > 1
        };
    }

    function buildAuthorizationHeader(apiKeyEnvVarName: string): string {
        return "";
    }

    function finalizeScriptContent(scriptContent: string): string {
        return `#!/usr/bin/env bash
LOGFILE="/tmp/quickshell_ai_debug.log"
echo "=== REQUEST STARTED AT $(date) ===" >> "$LOGFILE"

eval $(python3 - << 'ANTIGRAVITY_EOF'
import sys, json, re, shlex
text = sys.stdin.read()
m = re.search(r"--data \x27(.*)\x27", text)
if m:
    try:
        data = json.loads(m.group(1))
        print(f"PROMPT={shlex.quote(str(data.get('prompt', '')))}")
        print(f"MODEL={shlex.quote(str(data.get('model', '')))}")
        print(f"MODE={shlex.quote(str(data.get('mode', '')))}")
        print(f"CONVERSATION_ID={shlex.quote(str(data.get('conversationId', '')))}")
        print(f"IS_CONTINUE=1" if data.get("isContinue") else "IS_CONTINUE=0")
    except Exception as e:
        print(f"# Python error: {e}")
ANTIGRAVITY_EOF
)

if [ -z "$PROMPT" ]; then
    PROMPT="Hello"
fi

ARGS=("--print" "$PROMPT" "--dangerously-skip-permissions")
if [ -n "$MODEL" ]; then
    ARGS+=("--model" "$MODEL")
fi
if [ -n "$MODE" ] && [ "$MODE" != "default" ]; then
    ARGS+=("--mode" "$MODE")
fi
if [ -n "$CONVERSATION_ID" ]; then
    ARGS+=("--conversation" "$CONVERSATION_ID")
elif [ "$IS_CONTINUE" = "1" ]; then
    ARGS+=("--continue")
fi

echo "PARSED PROMPT: $PROMPT" >> "$LOGFILE"
echo "EXECUTING: /usr/bin/agy \${ARGS[*]}" >> "$LOGFILE"

exec /usr/bin/agy "\${ARGS[@]}"
`;
    }

    function parseResponseLine(line, message) {
        if (!line) return {};
        message.thinking = false;
        message.rawContent += line + "\n";
        message.content += line + "\n";
        return {};
    }
}
