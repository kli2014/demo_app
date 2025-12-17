# Security Copilot Agent - Quick Reference Guide

## Quick Start

### Running Security Analysis
```bash
# Run the basic security scanner
ruby .github/agents/security_scan.rb

# For comprehensive analysis, install and run Brakeman
gem install brakeman
brakeman -A

# Check for vulnerable dependencies
gem install bundler-audit
bundle audit check --update
```

## Common Security Tasks

### 1. Reviewing Code for Security Issues

**Ask the Security Copilot:**
- "Review this code for security vulnerabilities"
- "Is this controller action secure?"
- "How can I prevent SQL injection in this query?"
- "What security issues exist in this view?"

### 2. Implementing Authentication

**Current State:** No authentication exists

**Recommendation:**
```ruby
# Add to Gemfile
gem 'devise'

# Install and generate
bundle install
rails generate devise:install
rails generate devise User
```

**Ask the Security Copilot:**
- "How do I implement secure authentication?"
- "What are the best practices for password storage?"
- "How should I handle session management?"

### 3. Adding Authorization

**Current State:** No authorization exists

**Recommendation:**
```ruby
# Add to Gemfile
gem 'pundit'

# Install and generate
bundle install
rails generate pundit:install
rails generate pundit:policy User
```

**Example Policy:**
```ruby
# app/policies/user_policy.rb
class UserPolicy < ApplicationPolicy
  def update?
    user == record || user.admin?
  end
  
  def destroy?
    user.admin?
  end
end
```

**Ask the Security Copilot:**
- "How do I implement authorization?"
- "What authorization pattern should I use?"
- "How do I restrict access to certain actions?"

### 4. Securing Controllers

**Before (Insecure):**
```ruby
class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
  end
end
```

**After (Secure):**
```ruby
class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized
  
  def show
    authorize @user
  end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  end
end
```

### 5. Validating Input

**Add to Models:**
```ruby
class User < ActiveRecord::Base
  # Presence validation
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  
  # Email validation
  validates :email, presence: true, 
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
end

class Micropost < ActiveRecord::Base
  # Content validation
  validates :content, presence: true, length: { maximum: 140 }
  
  # Association validation
  validates :user_id, presence: true
  
  # Prevent XSS in content
  before_save :sanitize_content
  
  private
  
  def sanitize_content
    self.content = ActionController::Base.helpers.sanitize(content)
  end
end
```

### 6. Preventing SQL Injection

**Bad:**
```ruby
# NEVER do this
User.where("name = '#{params[:name]}'")
User.find_by_sql("SELECT * FROM users WHERE name = '#{params[:name]}'")
```

**Good:**
```ruby
# Use parameterized queries
User.where(name: params[:name])
User.where("name = ?", params[:name])
User.find_by(name: params[:name])
```

### 7. Preventing XSS

**In Views:**
```erb
<!-- Bad - XSS vulnerability -->
<%= raw @user.bio %>
<%= @user.bio.html_safe %>

<!-- Good - Escaped by default -->
<%= @user.bio %>

<!-- Good - When HTML is needed -->
<%= sanitize @user.bio, tags: %w(p br strong em a), attributes: %w(href) %>
```

### 8. Configuring Security Headers

**Add to Gemfile:**
```ruby
gem 'secure_headers'
```

**Configure in application.rb:**
```ruby
SecureHeaders::Configuration.default do |config|
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.hsts = "max-age=31536000; includeSubDomains"
end
```

### 9. Enabling HTTPS in Production

**In config/environments/production.rb:**
```ruby
# Force all access to the app over SSL
config.force_ssl = true
```

### 10. Rate Limiting

**Add to Gemfile:**
```ruby
gem 'rack-attack'
```

**Configure:**
```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttle('req/ip', limit: 300, period: 5.minutes) do |req|
  req.ip
end
```

## Security Checklist for Pull Requests

Before merging, verify:

- [ ] Strong parameters used for all mass assignment
- [ ] Input validated at model level
- [ ] Authorization checks in place for sensitive actions
- [ ] No SQL injection vulnerabilities
- [ ] No XSS vulnerabilities
- [ ] CSRF protection enabled (Rails default)
- [ ] No sensitive data in logs
- [ ] No hardcoded secrets or credentials
- [ ] Security headers configured
- [ ] HTTPS enforced in production
- [ ] Dependencies checked for vulnerabilities
- [ ] Tests include security scenarios

## Getting Help from Security Copilot

### In Pull Requests
Tag the security copilot agent in PR comments:
```
@security-copilot please review this code for security issues
```

### During Development
1. Open the agent documentation: `.github/agents/security-copilot.md`
2. Run the security scanner: `ruby .github/agents/security_scan.rb`
3. Check the security config: `.github/agents/security-config.yml`

### Common Questions

**Q: How do I secure user authentication?**
A: Consult `.github/agents/security-copilot.md` section on Authentication & Authorization

**Q: What validation should I add to my model?**
A: Ask: "What validations should I add to [ModelName] to ensure data integrity and security?"

**Q: Is my controller action secure?**
A: Share the code and ask: "Review this controller action for security vulnerabilities"

**Q: How do I prevent XSS in my views?**
A: Consult the XSS prevention section in the security copilot documentation

## Emergency Response

If a security vulnerability is discovered:

1. **Assess Impact**
   - Determine severity (Critical, High, Medium, Low)
   - Identify affected systems/data
   - Check if vulnerability has been exploited

2. **Immediate Actions**
   - Disable affected functionality if critical
   - Rotate compromised credentials
   - Apply temporary mitigations

3. **Remediation**
   - Consult Security Copilot for fix recommendations
   - Implement fix following security best practices
   - Test thoroughly
   - Deploy fix

4. **Post-Incident**
   - Document the vulnerability and fix
   - Update security tests
   - Review similar code for same issues
   - Update Security Copilot patterns if needed

## Resources

- **Agent Documentation**: `.github/agents/security-copilot.md`
- **Configuration**: `.github/agents/security-config.yml`
- **Scanner**: `.github/agents/security_scan.rb`
- **Rails Security Guide**: https://guides.rubyonrails.org/security.html
- **OWASP Top 10**: https://owasp.org/www-project-top-ten/
- **Brakeman**: https://brakemanscanner.org/

## Support

For security questions or concerns:
1. Review the Security Copilot documentation
2. Run the security scanner
3. Consult the Rails Security Guide
4. Engage with the Security Copilot Agent in your PR or issue
