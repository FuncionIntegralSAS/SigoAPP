import json
import os
import sys

transcript_path = r"C:\Users\User\.gemini\antigravity-ide\brain\3c3d2f96-6502-4436-ad58-0663e8c052e9\.system_generated\logs\transcript.jsonl"

def extract_latest_file_states():
    if not os.path.exists(transcript_path):
        print(f"Transcript not found at {transcript_path}")
        return

    # Track the latest content for write_to_file
    files = {}

    try:
        with open(transcript_path, 'r', encoding='utf-8') as f:
            for line in f:
                try:
                    step = json.loads(line.strip())
                    if step.get('type') == 'PLANNER_RESPONSE' and 'tool_calls' in step:
                        for tool_call in step['tool_calls']:
                            args = tool_call.get('arguments', {})
                            name = tool_call.get('name')
                            
                            if name == 'default_api:write_to_file':
                                target = args.get('TargetFile')
                                content = args.get('CodeContent')
                                if target and content:
                                    files[target] = content
                                    
                            # Note: replace_file_content is harder to reconstruct 
                            # because it applies a diff. But we can print which files 
                            # were modified.
                except json.JSONDecodeError:
                    pass
    except Exception as e:
        print(f"Error reading transcript: {e}")

    for target, content in files.items():
        if "physical_count_service.dart" in target or "physical_count_provider.dart" in target or "physical_count_opening_tab.dart" in target or "warehouse_model.dart" in target or "physical_count_model.dart" in target:
            print(f"Recovered full content for: {target}")
            # print(content[:100] + "...")

    print("Checking if we have the full content for the files...")

extract_latest_file_states()
