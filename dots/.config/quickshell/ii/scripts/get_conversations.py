#!/usr/bin/env python3
import sys
import glob
import os
import json
import re

def clean_prompt(text):
    if not text:
        return ""
    text = re.sub(r'<USER_REQUEST>\s*', '', text)
    text = re.sub(r'</USER_REQUEST>.*', '', text, flags=re.DOTALL)
    text = re.sub(r'<ADDITIONAL_METADATA>.*', '', text, flags=re.DOTALL)
    return text.strip().replace('\n', ' ')

def get_first_prompt(cid):
    for base in ['antigravity-cli', 'antigravity']:
        log_path = f'/home/coil/.gemini/{base}/brain/{cid}/.system_generated/logs/transcript.jsonl'
        if os.path.exists(log_path):
            try:
                with open(log_path, 'r', encoding='utf-8') as fp:
                    for line in fp:
                        d = json.loads(line)
                        if d.get('type') == 'USER_INPUT' or d.get('source') == 'USER_EXPLICIT':
                            c = d.get('content', '').strip()
                            cleaned = clean_prompt(c)
                            if cleaned:
                                return cleaned[:60]
            except Exception:
                pass
        msg_dir = f'/home/coil/.gemini/{base}/brain/{cid}/.system_generated/messages'
        if os.path.exists(msg_dir):
            for mfile in sorted(glob.glob(f'{msg_dir}/*.json')):
                try:
                    with open(mfile, 'r', encoding='utf-8') as fp:
                        md = json.load(fp)
                        if md.get('role') == 'user':
                            c = md.get('rawContent', '').strip()
                            cleaned = clean_prompt(c)
                            if cleaned:
                                return cleaned[:60]
                except Exception:
                    pass
    return f'Session {cid[:8]}'

def get_conversation_messages(cid):
    messages = []
    for base in ['antigravity-cli', 'antigravity']:
        log_path = f'/home/coil/.gemini/{base}/brain/{cid}/.system_generated/logs/transcript.jsonl'
        if os.path.exists(log_path):
            try:
                with open(log_path, 'r', encoding='utf-8') as fp:
                    for line in fp:
                        d = json.loads(line)
                        stype = d.get('type', '')
                        source = str(d.get('source', ''))
                        content = d.get('content', '')
                        if not content:
                            continue
                        if stype == 'USER_INPUT' or source == 'USER_EXPLICIT':
                            cleaned = clean_prompt(content)
                            if cleaned:
                                messages.append({
                                    'role': 'user',
                                    'rawContent': cleaned,
                                    'done': True,
                                    'thinking': False
                                })
                        elif stype == 'PLANNER_RESPONSE' or source == 'MODEL':
                            # Remove internal XML or system blocks if any
                            cleaned = re.sub(r'<think>.*?</think>', '', content, flags=re.DOTALL).strip()
                            if cleaned:
                                messages.append({
                                    'role': 'assistant',
                                    'rawContent': cleaned,
                                    'done': True,
                                    'thinking': False
                                })
                if messages:
                    return messages
            except Exception:
                pass
    return messages

def main():
    if len(sys.argv) >= 3 and sys.argv[1] == 'get':
        cid = sys.argv[2]
        msgs = get_conversation_messages(cid)
        print(json.dumps(msgs))
        return

    results = []
    seen = set()

    for db_pattern in ['/home/coil/.gemini/antigravity-cli/conversations/*.db', '/home/coil/.gemini/antigravity/conversations/*.db']:
        for f in sorted(glob.glob(db_pattern), key=os.path.getmtime, reverse=True):
            cid = os.path.basename(f)[:-3]
            if cid in seen:
                continue
            seen.add(cid)
            title = get_first_prompt(cid)
            results.append({'id': cid, 'title': title, 'desc': f'Session {cid[:8]}'})

    for f in sorted(glob.glob('/home/coil/.local/state/quickshell/ai/chats/*.json'), key=os.path.getmtime, reverse=True):
        bname = os.path.basename(f)[:-5]
        if bname in seen:
            continue
        seen.add(bname)
        try:
            with open(f, 'r', encoding='utf-8') as fp:
                data = json.load(fp)
                first_user = next((m['rawContent'] for m in data if m.get('role') == 'user'), bname)
                cleaned = clean_prompt(first_user)
                results.append({'id': bname, 'title': cleaned[:60], 'desc': f'Saved Chat: {bname}'})
        except Exception:
            results.append({'id': bname, 'title': bname, 'desc': 'Saved Chat'})

    print(json.dumps(results))

if __name__ == '__main__':
    main()
