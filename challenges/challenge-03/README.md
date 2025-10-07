# Challenge 03: Working in GitHub Codespaces Development Environment

## Overview

Open a pre-prepared repository in Codespaces and make basic configuration modifications. The goal is to show that the development environment is part of versioned code and can be automated and customized.

## Learning Objectives

- Understand the concept and benefits of cloud-based development environments
- Learn how to configure and customize Codespaces
- Experience consistent, reproducible development setups
- Understand how development environment configuration can be versioned with code

## Prerequisites

- GitHub account with Codespaces access
- Basic understanding of containerization concepts
- Familiarity with VS Code interface

## Tasks

### Task 1: Launch Codespaces Environment
1. Navigate to the provided repository
2. Create a new Codespace from the main branch
3. Wait for the environment to fully initialize
4. Explore the pre-configured development environment

### Task 2: Examine the Configuration
1. Explore the `.devcontainer` folder structure
   - Review `devcontainer.json` configuration
   - Examine the Dockerfile or base image settings
   - Understand the installed extensions and tools
2. Review the workspace configuration
   - Check VS Code settings and extensions
   - Explore any pre-configured tasks or launch configurations

### Task 3: Customize Your Environment
Choose and implement several of the following customizations:

**Basic Customizations:**
- Add a new VS Code extension to the devcontainer configuration
- Modify the container image or add new software packages
- Update VS Code settings or themes
- Add custom aliases or shell configurations

**Advanced Customizations:**
- Configure additional development tools or language servers
- Set up custom environment variables
- Add initialization scripts or setup commands
- Configure port forwarding for development services

### Task 4: Test Your Changes
1. Commit and push your configuration changes
2. Create a new Codespace to test your modifications
3. Verify that your customizations are applied automatically
4. Share your environment with a teammate (if working in pairs)

### Task 5: Environment Automation
1. Add a setup script that runs automatically when Codespace starts
2. Configure the development services (databases, APIs) to start automatically
3. Create custom tasks in VS Code for common development workflows
4. Document your environment setup for other developers

## Success Criteria

- [ ] Successfully launched and used a GitHub Codespace
- [ ] Modified the devcontainer configuration
- [ ] Customized the development environment to your preferences
- [ ] Tested configuration changes in a new Codespace
- [ ] Understand how to version and share development environment configurations
- [ ] Created automated setup processes for the development environment

## Key Concepts to Understand

- **Infrastructure as Code for Dev Environments**: Development environments can be defined, versioned, and shared
- **Reproducible Setups**: Every developer gets the same consistent environment
- **Cloud-Native Development**: Development happens in the cloud, reducing local machine dependencies
- **Onboarding Acceleration**: New team members can start coding immediately without setup time

## Additional Resources

- [GitHub Codespaces documentation](https://docs.github.com/en/codespaces)
- [Dev containers specification](https://containers.dev/)
- [Codespaces configuration reference](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/adding-a-dev-container-configuration)
- [VS Code in Codespaces](https://code.visualstudio.com/docs/remote/codespaces)

## Solution

[Solution Steps](/solutions/challenge-03/README.md)