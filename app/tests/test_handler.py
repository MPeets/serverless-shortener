import json

import boto3
import pytest
from moto import mock_aws

import handler as shortener


TABLE_NAME = "test-short-links"


@pytest.fixture
def table(monkeypatch):
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
    monkeypatch.setenv("AWS_REGION", "us-east-1")
    monkeypatch.setenv("TABLE_NAME", TABLE_NAME)

    with mock_aws():
        dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
        table = dynamodb.create_table(
            TableName=TABLE_NAME,
            KeySchema=[{"AttributeName": "slug", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "slug", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        yield table


def test_post_shorten_writes_url_to_dynamodb(table, monkeypatch):
    monkeypatch.setattr(shortener.secrets, "token_urlsafe", lambda _size: "abc123")

    response = shortener.handler(
        _event("POST", "/shorten", {"url": "https://example.com/docs"}),
        None,
    )

    assert response["statusCode"] == 201
    assert json.loads(response["body"]) == {
        "slug": "abc123",
        "url": "https://example.com/docs",
    }
    item = table.get_item(Key={"slug": "abc123"})["Item"]
    assert item["url"] == "https://example.com/docs"


def test_get_slug_redirects_to_stored_url(table):
    table.put_item(Item={"slug": "abc123", "url": "https://example.com/docs"})

    response = shortener.handler(_event("GET", "/abc123"), None)

    assert response == {
        "statusCode": 302,
        "headers": {"Location": "https://example.com/docs"},
        "body": "",
    }


def test_get_unknown_slug_returns_not_found(table):
    response = shortener.handler(_event("GET", "/missing"), None)

    assert response["statusCode"] == 404
    assert json.loads(response["body"]) == {"message": "Short URL not found"}


def test_post_shorten_rejects_invalid_url(table):
    response = shortener.handler(_event("POST", "/shorten", {"url": "ftp://example.com"}), None)

    assert response["statusCode"] == 400
    assert json.loads(response["body"]) == {"message": "url must be an http or https URL"}


def test_post_shorten_rejects_invalid_json(table):
    response = shortener.handler(
        {
            "requestContext": {"http": {"method": "POST"}},
            "rawPath": "/shorten",
            "body": "{invalid",
        },
        None,
    )

    assert response["statusCode"] == 400
    assert json.loads(response["body"]) == {"message": "Request body must be valid JSON"}


def test_unsupported_route_returns_not_found(table):
    response = shortener.handler(_event("DELETE", "/abc123"), None)

    assert response["statusCode"] == 404
    assert json.loads(response["body"]) == {"message": "Not found"}


def _event(method, path, body=None):
    return {
        "requestContext": {"http": {"method": method}},
        "rawPath": path,
        "body": json.dumps(body) if body is not None else None,
    }
