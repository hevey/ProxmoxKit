import Foundation
import Testing
@testable import ProxmoxKit

// MARK: - ProxmoxConfig Tests

@Test("ProxmoxConfig default values")
func proxmoxConfigDefaultValues() {
    let config = ProxmoxConfig.default
    
    #expect(config.baseURL.absoluteString == "https://localhost:8006")
    #expect(config.timeout == 30)
    #expect(config.retryCount == 3)
    #expect(config.validateSSL == true)
}

@Test("ProxmoxConfig custom values")
func proxmoxConfigCustomValues() {
    let customURL = URL(string: "https://example.com:8006")!
    let config = ProxmoxConfig(
        baseURL: customURL,
        timeout: 60,
        retryCount: 5,
        validateSSL: false
    )
    
    #expect(config.baseURL == customURL)
    #expect(config.timeout == 60)
    #expect(config.retryCount == 5)
    #expect(config.validateSSL == false)
}

// MARK: - ProxmoxClient Tests

@Test("ProxmoxClient creation")
func proxmoxClientCreation() throws {
    let client = try ProxmoxClient.create(host: "192.168.1.100")
    
    #expect(client.config.baseURL.host == "192.168.1.100")
    #expect(client.config.baseURL.port == 8006)
    #expect(client.config.baseURL.scheme == "https")
}

@Test("ProxmoxClient creation with custom port")
func proxmoxClientCreationWithCustomPort() throws {
    let client = try ProxmoxClient.create(host: "192.168.1.100", port: 8080)
    
    #expect(client.config.baseURL.host == "192.168.1.100")
    #expect(client.config.baseURL.port == 8080)
    #expect(client.config.baseURL.scheme == "https")
}

@Test("ProxmoxClient creation with HTTP")
func proxmoxClientCreationWithHTTP() throws {
    let client = try ProxmoxClient.create(
        host: "192.168.1.100",
        port: 8080,
        useHTTPS: false
    )
    
    #expect(client.config.baseURL.host == "192.168.1.100")
    #expect(client.config.baseURL.port == 8080)
    #expect(client.config.baseURL.scheme == "http")
}

@Test("ProxmoxClient creation with SSL validation")
func proxmoxClientCreationWithSSLValidation() throws {
    let client = try ProxmoxClient.create(
        host: "pve.example.com",
        useHTTPS: true,
        validateSSL: true
    )
    
    #expect(client.config.baseURL.host == "pve.example.com")
    #expect(client.config.validateSSL == true)
}

@Test("ProxmoxClient creation with invalid host throws error")
func proxmoxClientCreationWithInvalidHost() {
    do {
        // Use a host with a space which will cause URL creation to fail
        let _ = try ProxmoxClient.create(host: " invalid host ")
        #expect(Bool(false), "Expected ProxmoxClient.create to throw an error for invalid host")
    } catch {
        // Verify it's the expected error type
        if case ProxmoxError.invalidConfiguration = error {
            #expect(Bool(true)) // Success - got the expected error
        } else {
            #expect(Bool(false), "Expected ProxmoxError.invalidConfiguration, got \(error)")
        }
    }
}

@Test("ProxmoxClient services are available")
func proxmoxClientServicesAvailable() throws {
    let client = try ProxmoxClient.create(host: "192.168.1.100")
    
    // Test that services can be accessed without error
    let _ = client.nodes
    let _ = client.vms  
    let _ = client.containers
    let _ = client.cluster
    
    // If we get here without error, the services are properly initialized
    #expect(Bool(true))
}

// MARK: - ProxmoxError Tests

@Test("ProxmoxError descriptions")
func proxmoxErrorDescriptions() {
    let authError = ProxmoxError.authenticationFailed("Invalid credentials")
    #expect(authError.localizedDescription == "Authentication failed: Invalid credentials")
    
    let networkError = ProxmoxError.networkError(URLError(.notConnectedToInternet))
    #expect(networkError.localizedDescription.contains("Network error"))
    
    let apiError = ProxmoxError.apiError(code: 401, message: "Unauthorized")
    #expect(apiError.localizedDescription == "API error (401): Unauthorized")
    
    let notAuthError = ProxmoxError.notAuthenticated
    #expect(notAuthError.localizedDescription == "Not authenticated with Proxmox API")
    
    let invalidResponseError = ProxmoxError.invalidResponse
    #expect(invalidResponseError.localizedDescription == "Invalid response from server")
}

// MARK: - Type Alias Tests

@Test("Type aliases are properly defined")
func typeAliases() {
    #expect(ProxmoxKit.self == ProxmoxClient.self)
    #expect(ProxmoxConfiguration.self == ProxmoxConfig.self)
    #expect(VM.self == VirtualMachine.self)
    #expect(Resource.self == ProxmoxResource.self)
    #expect(NodeManager.self == NodeService.self)
    #expect(VMManager.self == VMService.self)
    #expect(ContainerManager.self == ContainerService.self)
    #expect(ClusterManager.self == ClusterService.self)
}

// MARK: - URL Construction Tests

@Test("URL construction")
func urlConstruction() throws {
    let httpsClient = try ProxmoxClient.create(host: "pve.example.com")
    let expectedHTTPS = "https://pve.example.com:8006"
    #expect(httpsClient.config.baseURL.absoluteString == expectedHTTPS)
    
    let httpClient = try ProxmoxClient.create(
        host: "192.168.1.100",
        port: 8080,
        useHTTPS: false
    )
    let expectedHTTP = "http://192.168.1.100:8080"
    #expect(httpClient.config.baseURL.absoluteString == expectedHTTP)
}

// MARK: - Configuration Edge Cases

@Test("Configuration with special characters")
func configurationWithSpecialCharacters() throws {
    let client = try ProxmoxClient.create(host: "pve-server.local")
    #expect(client.config.baseURL.host == "pve-server.local")
}

@Test("Configuration with IPv6")
func configurationWithIPv6() throws {
    let client = try ProxmoxClient.create(host: "[::1]")
    #expect(client.config.baseURL.host == "::1")
}

// MARK: - Error Equality Tests

@Test("ProxmoxError equality")
func proxmoxErrorEquality() {
    let error1 = ProxmoxError.notAuthenticated
    let error2 = ProxmoxError.notAuthenticated
    
    #expect(error1.localizedDescription == error2.localizedDescription)
    
    let authError1 = ProxmoxError.authenticationFailed("reason")
    let authError2 = ProxmoxError.authenticationFailed("different reason")
    
    #expect(authError1.localizedDescription != authError2.localizedDescription)
}

// MARK: - Configuration Validation Tests

@Test("Configuration timeout validation")
func configurationTimeoutValidation() {
    let config = ProxmoxConfig(
        baseURL: URL(string: "https://localhost:8006")!,
        timeout: 0,
        retryCount: 3,
        validateSSL: true
    )
    
    #expect(config.timeout == 0)
}

@Test("Configuration retry count validation")
func configurationRetryCountValidation() {
    let config = ProxmoxConfig(
        baseURL: URL(string: "https://localhost:8006")!,
        timeout: 30,
        retryCount: 0,
        validateSSL: true
    )
    
    #expect(config.retryCount == 0)
}

// MARK: - Client Initialization Edge Cases

@Test("Client with custom config")
func clientWithCustomConfig() {
    let customURL = URL(string: "https://custom.proxmox.server:9999")!
    let config = ProxmoxConfig(
        baseURL: customURL,
        timeout: 120,
        retryCount: 10,
        validateSSL: false
    )
    
    let client = ProxmoxClient(config: config)
    
    #expect(client.config.baseURL == customURL)
    #expect(client.config.timeout == 120)
    #expect(client.config.retryCount == 10)
    #expect(client.config.validateSSL == false)
}

