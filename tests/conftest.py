import os
from typing import IO
from unittest import mock

import aiohttp
import azure.storage.filedatalake
import azure.storage.filedatalake.aio
import pytest

from .mocks import (
    MockAsyncPageIterator,
    MockDirectoryClient,
    mock_vision_response,
)


@pytest.fixture
def mock_azurehttp_calls(monkeypatch):
    def mock_post(*args, **kwargs):
        if kwargs.get("url").endswith("computervision/retrieval:vectorizeText"):
            return mock_vision_response()
        elif kwargs.get("url").endswith("computervision/retrieval:vectorizeImage"):
            return mock_vision_response()
        else:
            raise Exception("Unexpected URL for mock call to ClientSession.post()")

    monkeypatch.setattr(aiohttp.ClientSession, "post", mock_post)


@pytest.fixture
def mock_blob_container_client_exists(monkeypatch):
    async def mock_exists(*args, **kwargs):
        return True

    monkeypatch.setattr("azure.storage.blob.aio.ContainerClient.exists", mock_exists)


@pytest.fixture
def mock_blob_container_client_does_not_exist(monkeypatch):
    async def mock_exists(*args, **kwargs):
        return False

    monkeypatch.setattr("azure.storage.blob.aio.ContainerClient.exists", mock_exists)


@pytest.fixture
def mock_env(monkeypatch):
    with mock.patch.dict(os.environ, clear=True):
        monkeypatch.setenv("AZURE_STORAGE_ACCOUNT", "test-storage-account")
        monkeypatch.setenv("AZURE_STORAGE_CONTAINER", "test-storage-container")
        monkeypatch.setenv("AZURE_STORAGE_RESOURCE_GROUP", "test-storage-rg")
        monkeypatch.setenv("AZURE_SUBSCRIPTION_ID", "test-storage-subid")
        yield


@pytest.fixture
def mock_data_lake_service_client(monkeypatch):
    def mock_init(self, *args, **kwargs):
        pass

    async def mock_aenter(self, *args, **kwargs):
        return self

    async def mock_aexit(self, *args, **kwargs):
        return self

    def mock_get_file_system_client(self, *args, **kwargs):
        return azure.storage.filedatalake.FileSystemClient(account_url=None, file_system_name=None, credential=None)

    def mock_init_service_client_aio(self, *args, **kwargs):
        self.filesystems = {}

    def mock_get_file_system_client_aio(self, name, *args, **kwargs):
        if name in self.filesystems:
            return self.filesystems[name]
        self.filesystems[name] = azure.storage.filedatalake.aio.FileSystemClient(
            account_url=None, file_system_name=None, credential=None
        )
        return self.filesystems[name]

    monkeypatch.setattr(azure.storage.filedatalake.DataLakeServiceClient, "__init__", mock_init)
    monkeypatch.setattr(
        azure.storage.filedatalake.DataLakeServiceClient, "get_file_system_client", mock_get_file_system_client
    )

    monkeypatch.setattr(azure.storage.filedatalake.aio.DataLakeServiceClient, "__init__", mock_init_service_client_aio)
    monkeypatch.setattr(azure.storage.filedatalake.aio.DataLakeServiceClient, "__aenter__", mock_aenter)
    monkeypatch.setattr(azure.storage.filedatalake.aio.DataLakeServiceClient, "__aexit__", mock_aexit)
    monkeypatch.setattr(
        azure.storage.filedatalake.aio.DataLakeServiceClient, "get_file_system_client", mock_get_file_system_client_aio
    )

    def mock_init_filesystem_aio(self, *args, **kwargs):
        self.directories = {}

    def mock_get_file_client(self, path, *args, **kwargs):
        return azure.storage.filedatalake.aio.DataLakeFileClient(
            account_url=None, file_system_name=None, file_path=path, credential=None
        )

    async def mock_exists_aio(self, *args, **kwargs):
        return False

    async def mock_create_filesystem_aio(self, *args, **kwargs):
        pass

    async def mock_create_directory_aio(self, directory, *args, **kwargs):
        if directory in self.directories:
            return self.directories[directory]
        self.directories[directory] = azure.storage.filedatalake.aio.DataLakeDirectoryClient(directory)
        return self.directories[directory]

    def mock_get_root_directory_client_aio(self, *args, **kwargs):
        if "/" in self.directories:
            return self.directories["/"]
        self.directories["/"] = azure.storage.filedatalake.aio.DataLakeDirectoryClient("/")
        self.directories["/"].child_directories = self.directories
        return self.directories["/"]

    def mock_get_paths(self, *args, **kwargs):
        paths = ["a.txt", "b.txt", "c.txt"]
        if kwargs.get("path") == "OID_X":
            paths = [f"OID_X/{path}" for path in paths]
        return MockAsyncPageIterator([azure.storage.filedatalake.PathProperties(name=path) for path in paths])

    monkeypatch.setattr(azure.storage.filedatalake.FileSystemClient, "__init__", mock_init)
    monkeypatch.setattr(azure.storage.filedatalake.FileSystemClient, "get_file_client", mock_get_file_client)

    monkeypatch.setattr(azure.storage.filedatalake.aio.FileSystemClient, "__init__", mock_init_filesystem_aio)
    monkeypatch.setattr(azure.storage.filedatalake.aio.FileSystemClient, "__aenter__", mock_aenter)
    monkeypatch.setattr(azure.storage.filedatalake.aio.FileSystemClient, "__aexit__", mock_aexit)

    monkeypatch.setattr(azure.storage.filedatalake.aio.FileSystemClient, "exists", mock_exists_aio)
    monkeypatch.setattr(azure.storage.filedatalake.aio.FileSystemClient, "get_file_client", mock_get_file_client)
    monkeypatch.setattr(
        azure.storage.filedatalake.aio.FileSystemClient, "create_file_system", mock_create_filesystem_aio
    )
    monkeypatch.setattr(azure.storage.filedatalake.aio.FileSystemClient, "get_paths", mock_get_paths)

    monkeypatch.setattr(azure.storage.filedatalake.aio.FileSystemClient, "create_directory", mock_create_directory_aio)
    monkeypatch.setattr(
        azure.storage.filedatalake.aio.FileSystemClient,
        "_get_root_directory_client",
        mock_get_root_directory_client_aio,
    )

    def mock_init_file(self, *args, **kwargs):
        self.path = kwargs.get("file_path")
        self.acl = ""

    def mock_url(self, *args, **kwargs):
        return f"https://test.blob.core.windows.net/{self.path}"

    def mock_download_file(self, *args, **kwargs):
        return azure.storage.filedatalake.StorageStreamDownloader(None)

    async def mock_download_file_aio(self, *args, **kwargs):
        return azure.storage.filedatalake.aio.StorageStreamDownloader(None)

    async def mock_get_access_control(self, *args, **kwargs):
        if self.path == "a.txt":
            return {"acl": "user:A-USER-ID:r-x,group:A-GROUP-ID:r-x"}
        if self.path == "b.txt":
            return {"acl": "user:B-USER-ID:r-x,group:B-GROUP-ID:r-x"}
        if self.path == "c.txt":
            return {"acl": "user:C-USER-ID:r-x,group:C-GROUP-ID:r-x"}

        raise Exception(f"Unexpected path {self.path}")

    async def mock_upload_data_aio(self, *args, **kwargs):
        self.uploaded = True
        pass

    monkeypatch.setattr(azure.storage.filedatalake.DataLakeFileClient, "__init__", mock_init_file)
    monkeypatch.setattr(azure.storage.filedatalake.DataLakeFileClient, "download_file", mock_download_file)
    monkeypatch.setattr(
        azure.storage.filedatalake.aio.DataLakeFileClient, "get_access_control", mock_get_access_control
    )
    monkeypatch.setattr(azure.storage.filedatalake.aio.DataLakeFileClient, "__init__", mock_init_file)
    monkeypatch.setattr(azure.storage.filedatalake.aio.DataLakeFileClient, "url", property(mock_url))
    monkeypatch.setattr(azure.storage.filedatalake.aio.DataLakeFileClient, "__aenter__", mock_aenter)
    monkeypatch.setattr(azure.storage.filedatalake.aio.DataLakeFileClient, "__aexit__", mock_aexit)
    monkeypatch.setattr(azure.storage.filedatalake.aio.DataLakeFileClient, "download_file", mock_download_file_aio)
    monkeypatch.setattr(
        azure.storage.filedatalake.aio.DataLakeFileClient, "get_access_control", mock_get_access_control
    )
    monkeypatch.setattr(azure.storage.filedatalake.aio.DataLakeFileClient, "upload_data", mock_upload_data_aio)

    def mock_init_directory(self, path, *args, **kwargs):
        self.path = path
        self.files = {}

    async def mock_get_directory_properties(self, *args, **kwargs):
        return azure.storage.filedatalake.DirectoryProperties()

    async def mock_get_access_control(self, *args, **kwargs):
        return {"owner": "OID_X"}

    def mock_directory_get_file_client(self, *args, **kwargs):
        path = kwargs.get("file")
        if path in self.files:
            return self.files[path]
        self.files[path] = azure.storage.filedatalake.aio.DataLakeFileClient(path)
        return self.files[path]

    async def mock_update_access_control_recursive_aio(self, acl, *args, **kwargs):
        for file in self.files.values():
            if len(file.acl) > 0:
                file.acl += ","
            file.acl += acl
        if self.path == "/":
            for directory in self.child_directories.values():
                await mock_update_access_control_recursive_aio(directory, acl)

    async def mock_close_aio(self, *args, **kwargs):
        pass

    monkeypatch.setattr(azure.storage.filedatalake.aio.DataLakeDirectoryClient, "__init__", mock_init_directory)
    monkeypatch.setattr(azure.storage.filedatalake.aio.DataLakeDirectoryClient, "__aenter__", mock_aenter)
    monkeypatch.setattr(azure.storage.filedatalake.aio.DataLakeDirectoryClient, "__aexit__", mock_aexit)
    monkeypatch.setattr(
        azure.storage.filedatalake.aio.DataLakeDirectoryClient, "get_file_client", mock_directory_get_file_client
    )
    monkeypatch.setattr(
        azure.storage.filedatalake.aio.DataLakeDirectoryClient,
        "update_access_control_recursive",
        mock_update_access_control_recursive_aio,
    )
    monkeypatch.setattr(
        azure.storage.filedatalake.aio.DataLakeDirectoryClient,
        "get_directory_properties",
        mock_get_directory_properties,
    )
    monkeypatch.setattr(
        azure.storage.filedatalake.aio.DataLakeDirectoryClient, "get_access_control", mock_get_access_control
    )
    monkeypatch.setattr(azure.storage.filedatalake.aio.DataLakeDirectoryClient, "close", mock_close_aio)

    def mock_readinto(self, stream: IO[bytes]):
        stream.write(b"texttext")
        return 8

    monkeypatch.setattr(azure.storage.filedatalake.StorageStreamDownloader, "__init__", mock_init)
    monkeypatch.setattr(azure.storage.filedatalake.StorageStreamDownloader, "readinto", mock_readinto)

    monkeypatch.setattr(azure.storage.filedatalake.aio.StorageStreamDownloader, "__init__", mock_init)
    monkeypatch.setattr(azure.storage.filedatalake.aio.StorageStreamDownloader, "readinto", mock_readinto)


@pytest.fixture
def mock_user_directory_client(monkeypatch):
    monkeypatch.setattr(
        azure.storage.filedatalake.aio.FileSystemClient,
        "get_directory_client",
        lambda *args, **kwargs: MockDirectoryClient(),
    )
