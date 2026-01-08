# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

# Create demo user
demo_user = User.find_or_create_by!(email: 'demo@example.com') do |u|
  u.name = 'Demo User'
end

# Create publishers
microsoft = Publisher.find_or_create_by!(name: 'Microsoft') do |p|
  p.description = 'Microsoft Corporation - Enterprise security solutions'
  p.website_url = 'https://microsoft.com'
end

contoso = Publisher.find_or_create_by!(name: 'Contoso Security') do |p|
  p.description = 'Contoso Security - Leading provider of security agents and services'
  p.website_url = 'https://contoso.com'
end

fabrikam = Publisher.find_or_create_by!(name: 'Fabrikam Cyber') do |p|
  p.description = 'Fabrikam Cyber - Threat intelligence and API security'
  p.website_url = 'https://fabrikam.com'
end

# Create Microsoft products (prerequisites)
sentinel = Product.find_or_create_by!(name: 'Microsoft Sentinel') do |p|
  p.description = 'Cloud-native SIEM and SOAR solution'
  p.overview = 'Microsoft Sentinel is a scalable, cloud-native, security information and event management (SIEM) and security orchestration, automation, and response (SOAR) solution.'
  p.product_type = 'SaaS'
  p.price_model = 'Paid'
  p.publisher = microsoft
  p.is_microsoft_product = true
  p.external_url = 'https://azure.microsoft.com/products/microsoft-sentinel'
end

copilot = Product.find_or_create_by!(name: 'Security Copilot') do |p|
  p.description = 'AI-powered security assistant'
  p.overview = 'Microsoft Security Copilot is an AI-powered security analysis tool that helps security teams quickly respond to threats.'
  p.product_type = 'SaaS'
  p.price_model = 'Paid'
  p.publisher = microsoft
  p.is_microsoft_product = true
  p.external_url = 'https://www.microsoft.com/security/business/ai-machine-learning/microsoft-security-copilot'
end

# Create main agent product
sentinel_agent = Product.find_or_create_by!(name: 'Sentinel Agent Pro') do |p|
  p.description = 'Advanced threat detection agent for Microsoft Sentinel'
  p.overview = 'Sentinel Agent Pro provides advanced threat detection, automated response capabilities, and deep integration with Microsoft Sentinel for comprehensive security monitoring.'
  p.product_type = 'Agent'
  p.price_model = 'Paid'
  p.price = 99.00
  p.publisher = contoso
  p.is_microsoft_product = false
  p.cta_text = 'Setup agent in Copilot'
  p.permissions = ['Read security data', 'Write incidents', 'Execute playbooks', 'Access Azure resources']
end

# Create connector
azure_connector = Product.find_or_create_by!(name: 'Azure Security Connector') do |p|
  p.description = 'Connect your Azure resources to security monitoring'
  p.overview = 'Azure Security Connector enables seamless integration between Azure resources and security monitoring tools.'
  p.product_type = 'Connector'
  p.price_model = 'Free'
  p.publisher = contoso
  p.is_microsoft_product = false
  p.permissions = ['Sentinel Contributor role required']
end

# Create SaaS product
threat_intel = Product.find_or_create_by!(name: 'Threat Intelligence API') do |p|
  p.description = 'Real-time threat intelligence feed'
  p.overview = 'Access real-time threat intelligence data including IOCs, malware signatures, and threat actor profiles.'
  p.product_type = 'SaaS'
  p.price_model = 'Paid'
  p.price = 149.00
  p.publisher = fabrikam
  p.is_microsoft_product = false
  p.cta_text = 'View API documentation'
end

# Create service product
xdr_service = Product.find_or_create_by!(name: 'Managed XDR Service') do |p|
  p.description = '24/7 managed detection and response'
  p.overview = 'Our expert team provides round-the-clock monitoring, threat hunting, and incident response services.'
  p.product_type = 'Service'
  p.price_model = 'Contact'
  p.publisher = contoso
  p.is_microsoft_product = false
  p.cta_text = 'Contact support'
end

# Create complementary product
compliance_reporter = Product.find_or_create_by!(name: 'Compliance Reporter') do |p|
  p.description = 'Automated compliance reporting and auditing'
  p.overview = 'Generate compliance reports for SOC 2, HIPAA, PCI-DSS, and other regulatory frameworks.'
  p.product_type = 'SaaS'
  p.price_model = 'Paid'
  p.price = 79.00
  p.publisher = fabrikam
  p.is_microsoft_product = false
end

# Set up product requirements for Sentinel Agent Pro
# Microsoft requirements
ProductRequirement.find_or_create_by!(product: sentinel_agent, required_product: sentinel, requirement_type: 'microsoft')
ProductRequirement.find_or_create_by!(product: sentinel_agent, required_product: copilot, requirement_type: 'microsoft')

# Partner requirements
ProductRequirement.find_or_create_by!(product: sentinel_agent, required_product: azure_connector, requirement_type: 'partner')
ProductRequirement.find_or_create_by!(product: sentinel_agent, required_product: threat_intel, requirement_type: 'partner')

# Complementary products
ProductRequirement.find_or_create_by!(product: sentinel_agent, required_product: xdr_service, requirement_type: 'complementary')
ProductRequirement.find_or_create_by!(product: sentinel_agent, required_product: compliance_reporter, requirement_type: 'complementary')

# Create sample subscriptions (demonstrating the grouped by publisher view)
main_subscription = Subscription.find_or_create_by!(user: demo_user, product: sentinel_agent) do |s|
  s.status = 'deployed'
  s.deployed_at = Time.current
end

# Child subscriptions for the main product
connector_sub = Subscription.find_or_create_by!(user: demo_user, product: azure_connector) do |s|
  s.status = 'action_required'
  s.error_message = "You don't have permissions to deploy this product. You need to be a Sentinel Contributor."
  s.parent_subscription = main_subscription
end

intel_sub = Subscription.find_or_create_by!(user: demo_user, product: threat_intel) do |s|
  s.status = 'deployed'
  s.deployed_at = Time.current
  s.parent_subscription = main_subscription
end

xdr_sub = Subscription.find_or_create_by!(user: demo_user, product: xdr_service) do |s|
  s.status = 'deployed'
  s.deployed_at = Time.current
  s.parent_subscription = main_subscription
  s.config_data = { 'contact_name' => 'John Doe', 'contact_email' => 'john@contoso.com', 'contact_phone' => '+1 555-123-4567' }
end

compliance_sub = Subscription.find_or_create_by!(user: demo_user, product: compliance_reporter) do |s|
  s.status = 'deployed'
  s.deployed_at = Time.current
  s.parent_subscription = main_subscription
end

puts "Seed data created successfully!"
puts "- Publishers: #{Publisher.count}"
puts "- Products: #{Product.count}"
puts "- Product Requirements: #{ProductRequirement.count}"
puts "- Subscriptions: #{Subscription.count}"
