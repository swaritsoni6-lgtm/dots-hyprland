import QtQuick
import qs.modules.common
import qs.modules.common.functions as CF

ApiStrategy {
    readonly property string apiKeyEnvVarName: "API_KEY"

    function buildEndpoint(model: AiModel): string {
        return "antigravity://localhost";
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
RAW_SCRIPT=$(cat << 'ANTIGRAVITY_EOF'
${scriptContent}
ANTIGRAVITY_EOF
)

PROMPT=$(echo "$RAW_SCRIPT" | grep -o '"prompt":"[^"]*"' | head -n1 | cut -d'"' -f4)
MODEL=$(echo "$RAW_SCRIPT" | grep -o '"model":"[^"]*"' | head -n1 | cut -d'"' -f4)
MODE=$(echo "$RAW_SCRIPT" | grep -o '"mode":"[^"]*"' | head -n1 | cut -d'"' -f4)
CONVERSATION_ID=$(echo "$RAW_SCRIPT" | grep -o '"conversationId":"[^"]*"' | head -n1 | cut -d'"' -f4)
IS_CONTINUE=$(echo "$RAW_SCRIPT" | grep -o '"isContinue":true')

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
elif [ -n "$IS_CONTINUE" ]; then
    ARGS+=("--continue")
fi

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
