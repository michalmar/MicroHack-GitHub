# MicroHack: GitHub for Modern Development

Welcome to the GitHub MicroHack! This hands-on workshop explores modern software development practices using GitHub's comprehensive development platform. Learn how to leverage AI assistance, implement robust DevSecOps practices, and build scalable microservices architectures.

## Workshop Overview

This MicroHack guides you through a comprehensive journey of modern development practices, from basic GitHub concepts to advanced AI-assisted development and enterprise-scale DevSecOps implementation.

### 🎯 Learning Objectives

- Master GitHub's collaborative development features and workflows
- Experience AI-assisted development with GitHub Copilot
- Implement modern CI/CD pipelines with advanced security integration
- Build and deploy microservices using cloud-native technologies
- Understand enterprise-scale development governance and best practices

### 🏗️ Sample Application

The workshop uses a **PetPal**, management system for pets, a web app built with microservices.

PetPal is a playful microservices‑based application that helps users manage their pets, track activities, and explore accessories. 

![PetPal web app](./solutions/challenge-06/docs/app-full.png)

#### Backend Services
- **🐾 Pet Service** (Port 8000) - Core pet management with CRUD operations
- **📊 Activity Service** (Port 8001) - Pet activity tracking and analytics  
- **🛍️ Accessory Service** (Port 8002) - Inventory management for pet accessories

Each service demonstrates modern development practices including:
- RESTful API design with FastAPI
- Azure CosmosDB integration
- Containerization with Docker
- Comprehensive testing strategies
- OpenAPI documentation
- Health monitoring and observability

## 🏆 MicroHack Challenges

This workshop consists of 11 progressive challenges designed to build comprehensive GitHub and modern development expertise:

### Foundation Challenges
| Challenge | Title | Focus Area | Duration |
|-----------|-------|------------|----------|
| [01](/challenges/challenge-01/README.md) | **Access and Identity** | GitHub organization setup, identity management strategies | 30 min |
| [02](/challenges/challenge-02/README.md) | **GitHub Copilot Introduction** | AI-assisted development fundamentals | 45 min |
| [03](/challenges/challenge-03/README.md) | **GitHub Codespaces** | Cloud development environments | 45 min |

### Collaboration and Planning
| Challenge | Title | Focus Area | Duration |
|-----------|-------|------------|----------|
| [04](/challenges/challenge-04/README.md) | **Brainstorming with AI, project management** | Requirements gathering, constitution and standards, project management | 20 min |
| [05](/challenges/challenge-05/README.md) | **GitHub Copilot – From Enabled to Effective** | Copilot best practices, customization and guidance | 30 min |

### Development and Implementation  
| Challenge | Title | Focus Area | Duration |
|-----------|-------|------------|----------|
| [06](/challenges/challenge-06/README.md) | **Design a new microservice with Copilot** | AI-assisted architecture design, specs | 20 min |
| [07](/challenges/challenge-07/README.md) | **Implementation and testing** | Specs-drive development, local testing and integration | 45 min |

### Infrastructure and Deployment
| Challenge | Title | Focus Area | Duration |
|-----------|-------|------------|----------|
| [08](/challenges/challenge-08/README.md) | **Infrastructure as Code** | Azure deployment, security patterns | 90 min |
| [09](/challenges/challenge-09/README.md) | **CI/CD with GitHub Actions** | Automated pipelines, deployment strategies | 90 min |

### Advanced Topics
| Challenge | Title | Focus Area | Duration |
|-----------|-------|------------|----------|
| [10](/challenges/challenge-10/README.md) | **DevSecOps and Governance** | Security integration, compliance automation | 90 min |
| [11](/challenges/challenge-11/README.md) | **AI Agent Automation** | Advanced Copilot agents, task delegation | 60 min |

### 📚 Bonus Challenge (Optional)
| Challenge | Title | Focus Area | Duration |
|-----------|-------|------------|----------|
| [12](/challenges/challenge-12/README.md) | **SRE with AI Agents** | Operational automation, monitoring, troubleshooting | 90 min |

## 🚀 Quick Start Guide

### Prerequisites
- GitHub account with Copilot access
- Azure subscription (will be provided)
- Basic understanding of software development
- Familiarity with containerization concepts

### Workshop Setup

1. **Fork this repository** to your GitHub account
2. **Join the GitHub Organization** (instructor will provide details)
3. **Access Azure environment** (credentials will be provided)
4. **Install required tools**:
   - VS Code with GitHub Copilot extension
   - Docker Desktop
   - Azure CLI
   - Git

### Starting the Workshop

1. Begin with [Challenge 01](/challenges/challenge-01/README.md)
2. Complete challenges sequentially
3. Use provided solutions as reference when needed
4. Ask instructors for help when stuck

### Local Development in GitHub Codespaces (Preparation)

This section helps you run the sample microservices and a local Azure Cosmos DB Emulator entirely inside a GitHub Codespace. It is especially useful for completing challenges that involve data persistence and integration tests without deploying real Azure resources.

#### ✅ Overview
You will:
1. Start (or reuse) your Codespace.
2. Launch the Azure Cosmos DB Emulator as a Docker container.
3. (Optionally) Trust its self‑signed certificate for HTTPS.
4. Export environment variables for the pet service tests / SDK usage.
5. Run the provided emulator connectivity test.

#### 1. Open / Start Your Codespace
Fork (or use a workshop-provided repo) and open it in a Codespace with Docker enabled (default images already have Docker + Python tools available).

#### 2. Pull and Run the Cosmos DB Emulator
```bash
docker pull mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator:latest

docker run \
   --name cosmos-emulator \
   --detach \
   --publish 8081:8081 \
   --publish 10250-10255:10250-10255 \
   --env AZURE_COSMOS_EMULATOR_PARTITION_COUNT=2 \
   --env AZURE_COSMOS_EMULATOR_ENABLE_DATA_PERSISTENCE=true \
   mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator:latest
```
Wait for readiness:
```bash
docker logs -f cosmos-emulator | grep -i "Started Azure Cosmos DB Emulator" || true
```

Why these ports?
- 8081: HTTPS endpoint + Data Explorer
- 10250-10255: Backend gateway/data ports required by the SDK

Inside Codespaces your application code should use `localhost` (NOT the forwarded public URL). Port forwarding (in the Ports panel) is only needed if you want to open the Data Explorer UI in a browser.

#### 5. Run the Connectivity Test
```bash
cd backend/pet-service
python -m pip install -r requirements.txt
python test_cosmos_emulator.py
```
Expected last line:
```
Cosmos emulator connectivity test passed.
```

## 🎓 Learning Path and Tips

### Recommended Approach
- **Focus on fundamentals first**: Challenges 1-5 establish core GitHub and Copilot skills
- **Build progressively**: Each challenge builds on previous knowledge
- **Practice extensively**: Use provided sample application for hands-on experience
- **Collaborate actively**: Work with peers, discuss approaches, share learnings

### Success Strategies
- **Leverage AI assistance**: Use Copilot throughout the workshop for faster learning
- **Don't skip testing**: Quality practices are essential for real-world success
- **Understand the 'why'**: Focus on understanding principles, not just completing tasks
- **Document your journey**: Keep notes on learnings and best practices
- **Ask questions**: Instructors and peers are valuable resources

## 🛠️ Technical Requirements

### Development Environment
- **VS Code** with GitHub Copilot extension
- **Docker Desktop** for containerization
- **Azure CLI** for cloud interactions
- **Git** for version control
- **Python 3.8+** for sample application
- **Node.js** (if exploring additional technologies)

### Cloud Resources
- **GitHub Organization** access (provided by instructor)
- **Azure subscription** with appropriate permissions
- **GitHub Copilot** license (Business/Enterprise recommended)

### Optional Tools
- **Postman** or **REST Client extension** for API testing
- **Azure Storage Explorer** for debugging storage issues
- **Terraform** or **Bicep** for advanced IaC scenarios

## 📚 Additional Resources

### GitHub Learning Resources
- [GitHub Skills](https://skills.github.com/) - Interactive learning courses
- [GitHub Docs](https://docs.github.com/) - Comprehensive documentation
- [GitHub Community](https://github.community/) - Community support and discussions

### AI-Assisted Development
- [Copilot Documentation](https://docs.github.com/en/copilot)
- [AI Pair Programming Best Practices](https://github.blog/2023-06-20-how-to-write-better-prompts-for-github-copilot/)
- [Responsible AI Development](https://github.com/github/copilot-research)

### DevOps and Cloud
- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [Microservices Patterns](https://microservices.io/)
- [Cloud Native Computing Foundation](https://www.cncf.io/)

## 🎯 Workshop Completion

### Minimum Success Criteria
- Complete challenges 1-7 (Foundation through Implementation)
- Successfully deploy at least one microservice to Azure
- Implement basic CI/CD pipeline
- Demonstrate effective use of GitHub Copilot

### Advanced Achievement
- Complete all 11 challenges
- Implement comprehensive DevSecOps practices
- Create reusable automation and templates
- Mentor other participants

### Post-Workshop
- Continue practicing with your own projects
- Join GitHub community discussions
- Contribute to open source projects using learned skills
- Share knowledge with your team and organization

---

**Ready to transform your development workflow?** 
Start with [Challenge 01: Access and Identity](/challenges/challenge-01/README.md) and begin your GitHub mastery journey! 🚀
