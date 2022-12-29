# Fig Dev Container Features

Add the Fig CLI to a Dev Container

## Usage

To use the feature from this repository, add the desired features to devcontainer.json.

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/withfig/features/fig:1": {}
    }
}
```
