# QVerisBot

Connect your AI Agents to 10,000+ agent skills and data sources.

## Overview

**QVerisBot** is the unified skill interface for OpenClaw, OpenCode, vibe coding, Claude Code, Cursor, and MCP-compatible agents. With QVerisBot, you can seamlessly integrate a vast ecosystem of agent skills and data sources including Finance, Weather, Search, and much more.

This repository contains the Docker implementation of QVerisBot, allowing you to quickly deploy and manage QVerisBot in containerized environments.

## Official Repository

The main QVerisBot project is hosted at: [github.com/QVerisAI/QVerisBot](https://github.com/QVerisAI/QVerisBot.git)

## About QVeris

Visit the **QVeris Official Website**: [https://qveris.ai](https://qveris.ai)

QVeris is building the platform for connecting AI Agents to enterprise-grade skills and data sources.

## Features

- 🤖 **10,000+ Agent Skills** - Access a comprehensive library of pre-built skills and integrations
- 🔌 **Unified Skill Interface** - Compatible with OpenClaw, OpenCode, vibe coding, Claude Code, Cursor, and MCP
- 📊 **Finance Integration** - Real-time financial data and analytics
- 🌤️ **Weather Services** - Global weather data and forecasting
- 🔍 **Search Capabilities** - Powerful search and information retrieval
- 📈 **Data Sources** - Connect to thousands of data sources
- 🐳 **Docker Support** - Easy containerized deployment

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Git

### Installation

```bash
git clone https://github.com/QVerisAI/QVerisBot.git
cd QVerisBot-docker
# build the image; it pre-populates /root/.config/matplotlib/matplotlibrc
docker build -f docker/Dockerfile -t qverisbot:latest .
# run the container; entrypoint will also ensure the file exists at startup
docker run -d --name qverisbot qverisbot:latest
```

> ⚠️ **Troubleshooting**: if you ever inspect the container and `/root/.config` is missing,
> the image build step created the directory, but a later volume mount or runtime
> change may have hidden it. The entrypoint script now recreates the
> `matplotlibrc` automatically, so the config will always be available inside the
> running container.

## Documentation

For detailed documentation, configuration options, and usage examples, please visit:
- [QVeris Official Website](https://qveris.ai)
- [QVerisBot GitHub Repository](https://github.com/QVerisAI/QVerisBot.git)

## Support

For issues, questions, or contributions, please visit the [QVerisBot GitHub Issues](https://github.com/QVerisAI/QVerisBot/issues) page.

## License

Please refer to the main [QVerisBot repository](https://github.com/QVerisAI/QVerisBot.git) for license information.

---

**QVeris** - Empowering AI Agents with Enterprise-Grade Skills and Data Sources
