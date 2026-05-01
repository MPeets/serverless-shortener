import base64
import json
import os
import secrets
import time
from urllib.parse import urlparse

import boto3


def handler(event, _context):
    method = _method(event)
    path = _path(event)

    if method == "POST" and path == "/shorten":
        return _shorten(event)

    if method == "GET" and path != "/":
        return _redirect(path.lstrip("/"))

    return _response(404, {"message": "Not found"})


def _shorten(event):
    try:
        body = _json_body(event)
    except (TypeError, ValueError, json.JSONDecodeError):
        return _response(400, {"message": "Request body must be valid JSON"})

    url = body.get("url") if isinstance(body, dict) else None
    if not _valid_url(url):
        return _response(400, {"message": "url must be an http or https URL"})

    slug = _new_slug()
    _table().put_item(
        Item={
            "slug": slug,
            "url": url,
            "created_at": int(time.time()),
        },
        ConditionExpression="attribute_not_exists(slug)",
    )

    return _response(201, {"slug": slug, "url": url})


def _redirect(slug):
    result = _table().get_item(Key={"slug": slug})
    item = result.get("Item")

    if item is None:
        return _response(404, {"message": "Short URL not found"})

    return {
        "statusCode": 302,
        "headers": {"Location": item["url"]},
        "body": "",
    }


def _json_body(event):
    body = event.get("body") or "{}"
    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8")
    return json.loads(body)


def _method(event):
    return (
        event.get("requestContext", {}).get("http", {}).get("method")
        or event.get("httpMethod")
        or ""
    ).upper()


def _path(event):
    return event.get("rawPath") or event.get("path") or "/"


def _valid_url(url):
    if not isinstance(url, str):
        return False

    parsed = urlparse(url)
    return parsed.scheme in {"http", "https"} and bool(parsed.netloc)


def _new_slug():
    return secrets.token_urlsafe(6).rstrip("=")


def _table():
    table_name = os.environ["TABLE_NAME"]
    region = os.environ.get("AWS_REGION", "eu-north-1")
    return boto3.resource("dynamodb", region_name=region).Table(table_name)


def _response(status_code, payload):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(payload),
    }
