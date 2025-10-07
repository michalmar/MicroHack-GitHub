# Challenge 07: Implementation and Local Testing

## Overview

Progressive development of a new component using Copilot and integration with the existing application. Emphasis on working with both local environment and cloud services.

## Learning Objectives

- Implement a microservice using AI-assisted development
- Practice test-driven development with Copilot
- Learn local development and testing strategies
- Understand integration patterns with existing services
- Experience debugging and troubleshooting with AI assistance

## Prerequisites

- Completed Challenge 06 (Design phase)
- Local development environment set up
- Docker and containerization knowledge
- Understanding of the existing pet management system
- Access to development/testing cloud resources

## Tasks

### Task 1: Environment Setup
1. **Local Development Environment**:
   - Set up development environment for your chosen technology stack
   - Configure local database (PostgreSQL, MongoDB, etc.)
   - Set up local message broker (Redis, RabbitMQ) if needed
   - Configure environment variables and secrets

2. **Integration with Existing Services**:
   - Clone and run existing pet management services locally
   - Configure service discovery or direct service communication
   - Set up local API gateway or load balancer
   - Test connectivity between services

### Task 2: Test-Driven Development Setup
1. **Testing Framework**:
   - Use Copilot to set up appropriate testing frameworks
   - Configure unit test, integration test, and end-to-end test structure
   - Set up test data management and cleanup
   - Configure test coverage reporting

2. **Test Planning**:
   - Generate test cases with Copilot based on your design specifications
   - Create test data fixtures and mock objects
   - Plan testing strategy for external service dependencies
   - Set up continuous testing in development workflow

### Task 3: Core Service Implementation
1. **Data Layer Implementation**:
   - Implement data models and repository patterns
   - Use Copilot to generate database access code
   - Implement data validation and error handling
   - Add database migrations and schema management

2. **Business Logic Layer**:
   - Implement core business logic with AI assistance
   - Add input validation and business rule enforcement
   - Implement error handling and logging
   - Add performance optimizations

3. **API Layer Implementation**:
   - Implement REST endpoints based on your OpenAPI specification
   - Use Copilot to generate route handlers and middleware
   - Add request/response validation
   - Implement proper HTTP status code handling

### Task 4: Integration Implementation
1. **Service-to-Service Communication**:
   - Implement synchronous API calls to existing services
   - Add retry logic and circuit breaker patterns
   - Implement asynchronous messaging if applicable
   - Add correlation ID tracking for distributed tracing

2. **Event Publishing and Consumption**:
   - Implement event publishing for significant business events
   - Add event consumers for relevant external events
   - Ensure idempotent event processing
   - Add event schema validation

### Task 5: Local Testing and Validation
1. **Unit Testing**:
   - Write comprehensive unit tests with Copilot assistance
   - Test business logic in isolation
   - Mock external dependencies appropriately
   - Achieve high test coverage

2. **Integration Testing**:
   - Test database interactions and data persistence
   - Test API endpoints with various input scenarios
   - Test error conditions and edge cases
   - Validate integration with existing services

3. **End-to-End Testing**:
   - Test complete user workflows
   - Validate business processes across service boundaries
   - Test performance under load
   - Validate error propagation and handling

### Task 6: Cloud Integration Testing
1. **Cloud Service Configuration**:
   - Configure cloud database connections
   - Set up cloud messaging services
   - Configure monitoring and logging services
   - Test cloud-specific features and limitations

2. **Deployment Testing**:
   - Create containerized version of your service
   - Test deployment to development environment
   - Validate configuration management
   - Test service discovery and health checks

### Task 7: Performance and Monitoring
1. **Performance Testing**:
   - Use Copilot to generate load testing scripts
   - Test service performance under various loads
   - Identify and optimize bottlenecks
   - Validate scalability characteristics

2. **Observability Implementation**:
   - Add structured logging throughout the service
   - Implement metrics collection and export
   - Add distributed tracing integration
   - Set up health check endpoints

## Success Criteria

- [ ] Successfully implemented new microservice with core functionality
- [ ] Achieved high test coverage with comprehensive test suite
- [ ] Successfully integrated with existing services locally
- [ ] Deployed and tested service in cloud environment
- [ ] Implemented proper error handling and resilience patterns
- [ ] Added observability and monitoring capabilities
- [ ] Validated performance meets design requirements

## Development Workflow with Copilot

### 1. Feature Implementation Cycle
```
1. Write failing test with Copilot assistance
2. Use Copilot to generate initial implementation
3. Refine and optimize the generated code
4. Run tests and fix any issues
5. Refactor with Copilot suggestions
6. Commit and push changes
```

### 2. Effective Copilot Prompts for Implementation
```
"Implement a repository pattern for managing pet health records with CRUD operations"

"Create a REST endpoint for scheduling veterinary appointments with proper validation"

"Generate unit tests for the appointment scheduling business logic"

"Add error handling and retry logic for external service calls"
```

### 3. Integration Testing Strategies
- Use Docker Compose for local multi-service testing
- Implement test containers for database testing
- Use service mocks for external dependencies
- Create integration test scenarios covering happy path and error conditions

## Debugging and Troubleshooting with AI

### Common Issues and AI Assistance
- Use Copilot Chat to analyze error messages and stack traces
- Get suggestions for debugging complex integration issues
- Generate test cases to reproduce and isolate problems
- Get recommendations for performance optimization

### Code Review with AI
- Use Copilot to review code for potential issues
- Get suggestions for code improvements and best practices
- Validate security considerations and vulnerabilities
- Check for compliance with coding standards

## Additional Resources

- [Test-driven development best practices](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
- [Microservices testing strategies](https://martinfowler.com/articles/microservice-testing/)
- [Docker Compose for development](https://docs.docker.com/compose/)
- [API testing with Postman](https://learning.postman.com/docs/writing-scripts/test-scripts/)
- [Performance testing tools](https://k6.io/docs/)

## Solution

[Solution Steps](/solutions/challenge-07/README.md)