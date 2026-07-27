import json
from collections import namedtuple
from io import BytesIO

import openai.types
from azure.core.credentials_async import AsyncTokenCredential
from azure.storage.blob import BlobProperties

MOCK_EMBEDDING_DIMENSIONS = 1536
MOCK_EMBEDDING_MODEL_NAME = "text-embedding-ada-002"
TEST_PNG_BYTES = (
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00"
    b"\x00\x1f\x15\xc4\x89\x00\x00\x00\rIDATx\xdac\xfc\xcf\xf0\xbf\x1e\x00\x06\x83\x02\x7f\x94\xad"
    b"\xd0\xeb\x00\x00\x00\x00IEND\xaeB`\x82"
)

MockToken = namedtuple("MockToken", ["token", "expires_on", "value"])


class MockAzureCredential(AsyncTokenCredential):

    async def get_token(self, *scopes, **kwargs):  # accept claims, enable_cae, etc.
        # Return a simple mock token structure with required attributes
        return MockToken("mock-token", 9999999999, "mock-token")


class MockBlob:
    def __init__(self):
        self.properties = BlobProperties(
            name="Financial Market Analysis Report 2023-7.png", content_settings={"content_type": "image/png"}
        )

    async def readall(self):
        return TEST_PNG_BYTES

    async def readinto(self, buffer: BytesIO):
        buffer.write(b"test")


class MockAsyncPageIterator:
    def __init__(self, data):
        self.data = data

    def __aiter__(self):
        return self

    async def __anext__(self):
        if not self.data:
            raise StopAsyncIteration
        return self.data.pop(0)  # This should be a list of dictionaries.


class MockResponse:
    def __init__(self, status, text=None, headers=None):
        self._text = text or ""
        self.status = status
        self.headers = headers or {}

    async def __aexit__(self, exc_type, exc, tb):
        pass

    async def __aenter__(self):
        return self

    async def text(self):
        return self._text

    async def json(self):
        return json.loads(self._text)

    def raise_for_status(self):
        if self.status != 200:
            raise Exception(f"HTTP status {self.status}")


class MockEmbeddingsClient:
    def __init__(self, create_embedding_response: openai.types.CreateEmbeddingResponse):
        self.create_embedding_response = create_embedding_response

    async def create(self, *args, **kwargs) -> openai.types.CreateEmbeddingResponse:
        return self.create_embedding_response


class MockClient:
    def __init__(self, embeddings_client):
        self.embeddings = embeddings_client


def mock_vision_response():
    return MockResponse(
        status=200,
        text=json.dumps(
            {
                "vector": [
                    0.011925711,
                    0.023533698,
                    0.010133852,
                    0.0063544377,
                    -0.00038590943,
                    0.0013952175,
                    0.009054946,
                    -0.033573493,
                    -0.002028305,
                ],
                "modelVersion": "2022-04-11",
            }
        ),
    )


# Mock DirectoryClient used in blobmanager.py:AdlsBlobManager
class MockDirectoryClient:
    async def get_directory_properties(self):
        # Return dummy properties to indicate directory exists
        return {"name": "test-directory"}

    async def get_access_control(self):
        # Return a dictionary with the owner matching the auth_client's user_oid
        return {"owner": "OID_X"}  # This should match the user_oid in auth_client

    def get_file_client(self, filename):
        # Return a file client for the given filename
        return MockFileClient(filename)


# Mock FileClient used in blobmanager.py:AdlsBlobManager
class MockFileClient:
    def __init__(self, path_name):
        self.path_name = path_name

    async def download_file(self):
        return MockBlob()
