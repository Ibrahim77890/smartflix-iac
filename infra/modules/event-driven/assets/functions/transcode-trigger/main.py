import base64
import json
import logging


def transcode_trigger(cloud_event):
    message = cloud_event.data.get("message", {})
    payload = message.get("data", "")

    decoded = ""
    if payload:
        decoded = base64.b64decode(payload).decode("utf-8")

    try:
        parsed = json.loads(decoded) if decoded else {}
    except json.JSONDecodeError:
        parsed = {"raw": decoded}

    logging.info("transcode-trigger received event: %s", parsed)
    return "ok"
