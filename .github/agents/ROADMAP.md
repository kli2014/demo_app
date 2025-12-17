# Security Enhancement Roadmap

This document provides a step-by-step roadmap for enhancing the security of the demo application.

## Current Security Status

### ✅ What's Already Secure
- **CSRF Protection**: Enabled by default in Rails
- **Strong Parameters**: Implemented in controllers (Rails 4+ feature)
- **Content Validation**: Basic length validation on microposts
- **SQL Injection Protection**: Using ActiveRecord with proper parameterization
- **XSS Protection**: Rails escapes output by default

### ⚠️ Security Gaps
- **No Authentication**: Anyone can access all endpoints
- **No Authorization**: Users can modify any user or micropost
- **Limited Input Validation**: Minimal validation on models
- **No Rate Limiting**: Vulnerable to brute force and DoS
- **No Security Headers**: Missing important HTTP security headers
- **HTTP Only**: HTTPS not enforced in production
- **No Session Security**: Default session configuration
- **No Audit Logging**: No security event logging

## Security Enhancement Roadmap

### Phase 1: Foundation (Priority: HIGH)

#### 1.1 Add Authentication
**Estimated Time:** 2-3 hours  
**Complexity:** Medium

**Steps:**
```bash
# Add Devise gem
echo "gem 'devise'" >> Gemfile
bundle install

# Generate Devise configuration
rails generate devise:install

# Add authentication to User model
rails generate devise User

# Run migrations
rake db:migrate
```

**Update Controllers:**
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  protect_from_forgery with: :exception
end
```

**Test:**
- Try accessing application without login
- Test registration, login, logout flows
- Verify password reset functionality

---

#### 1.2 Add Authorization
**Estimated Time:** 3-4 hours  
**Complexity:** Medium

**Steps:**
```bash
# Add Pundit gem
echo "gem 'pundit'" >> Gemfile
bundle install

# Generate Pundit configuration
rails generate pundit:install

# Generate policies
rails generate pundit:policy User
rails generate pundit:policy Micropost
```

**Implement Policies:**
```ruby
# app/policies/user_policy.rb
class UserPolicy < ApplicationPolicy
  def show?
    true  # Anyone can view users
  end
  
  def update?
    user == record || user.admin?
  end
  
  def destroy?
    user.admin?
  end
end

# app/policies/micropost_policy.rb
class MicropostPolicy < ApplicationPolicy
  def create?
    true  # Any authenticated user
  end
  
  def update?
    user == record.user
  end
  
  def destroy?
    user == record.user || user.admin?
  end
end
```

**Update Controllers:**
```ruby
# app/controllers/application_controller.rb
include Pundit
after_action :verify_authorized, except: :index

# app/controllers/microposts_controller.rb
def destroy
  @micropost = Micropost.find(params[:id])
  authorize @micropost
  @micropost.destroy
  redirect_to microposts_url
end
```

---

#### 1.3 Enhance Input Validation
**Estimated Time:** 1-2 hours  
**Complexity:** Low

**Update Models:**
```ruby
# app/models/user.rb
class User < ActiveRecord::Base
  has_many :microposts, dependent: :destroy
  
  validates :name, presence: true, 
                   length: { minimum: 2, maximum: 50 }
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    length: { maximum: 255 },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  
  before_save :downcase_email
  
  private
  
  def downcase_email
    self.email = email.downcase if email.present?
  end
end

# app/models/micropost.rb
class Micropost < ActiveRecord::Base
  belongs_to :user
  
  validates :content, presence: true, length: { maximum: 140 }
  validates :user_id, presence: true
  
  # Prevent XSS in content
  before_save :sanitize_content
  
  private
  
  def sanitize_content
    self.content = ActionController::Base.helpers.sanitize(content)
  end
end
```

---

### Phase 2: Hardening (Priority: MEDIUM)

#### 2.1 Configure Security Headers
**Estimated Time:** 30 minutes  
**Complexity:** Low

**Steps:**
```bash
# Add secure_headers gem
echo "gem 'secure_headers'" >> Gemfile
bundle install
```

**Configure:**
```ruby
# config/initializers/secure_headers.rb
SecureHeaders::Configuration.default do |config|
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.x_download_options = "noopen"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = %w(origin-when-cross-origin strict-origin-when-cross-origin)
  config.hsts = "max-age=#{1.year.to_i}; includeSubDomains"
  
  config.csp = {
    default_src: %w('self'),
    script_src: %w('self'),
    style_src: %w('self' 'unsafe-inline'),
    img_src: %w('self' data: https:),
    font_src: %w('self' data:),
    connect_src: %w('self'),
    frame_ancestors: %w('none')
  }
end
```

---

#### 2.2 Enforce HTTPS
**Estimated Time:** 15 minutes  
**Complexity:** Low

**Update Production Config:**
```ruby
# config/environments/production.rb
DemoApp::Application.configure do
  # Force all access over SSL
  config.force_ssl = true
  
  # Use secure cookies
  config.session_store :cookie_store,
    key: '_demo_app_session',
    secure: true,
    httponly: true,
    same_site: :lax
end
```

---

#### 2.3 Add Rate Limiting
**Estimated Time:** 1 hour  
**Complexity:** Medium

**Steps:**
```bash
# Add rack-attack gem
echo "gem 'rack-attack'" >> Gemfile
bundle install
```

**Configure:**
```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  # Throttle login attempts by IP
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/users/sign_in' && req.post?
      req.ip
    end
  end
  
  # Throttle API requests by IP
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip
  end
  
  # Block suspicious requests
  blocklist('block bad User-Agents') do |req|
    req.user_agent =~ /bad|malicious|bot/i
  end
end

# config/application.rb
config.middleware.use Rack::Attack
```

---

### Phase 3: Advanced Security (Priority: LOW)

#### 3.1 Add Security Monitoring
**Estimated Time:** 2-3 hours  
**Complexity:** High

**Steps:**
```ruby
# config/initializers/security_logger.rb
class SecurityLogger
  def self.log_event(event_type, details = {})
    Rails.logger.warn("[SECURITY] #{event_type}: #{details}")
  end
end

# Usage in controllers
SecurityLogger.log_event('unauthorized_access', {
  user_id: current_user&.id,
  resource: params[:controller],
  action: params[:action],
  ip: request.remote_ip
})
```

---

#### 3.2 Add Two-Factor Authentication
**Estimated Time:** 4-6 hours  
**Complexity:** High

**Steps:**
```bash
# Add two-factor authentication
echo "gem 'devise-two-factor'" >> Gemfile
echo "gem 'rqrcode'" >> Gemfile
bundle install
```

---

#### 3.3 Implement Content Security Policy Reporting
**Estimated Time:** 1-2 hours  
**Complexity:** Medium

**Configure CSP Reporting:**
```ruby
# config/initializers/secure_headers.rb
config.csp = {
  default_src: %w('self'),
  report_uri: %w(/csp_reports)
}

# Add endpoint to receive CSP violation reports
# config/routes.rb
post '/csp_reports', to: 'csp_reports#create'
```

---

## Testing Security Enhancements

### Manual Testing Checklist
- [ ] Attempt to access resources without authentication
- [ ] Try to modify other users' data
- [ ] Test SQL injection attempts
- [ ] Test XSS injection attempts
- [ ] Verify CSRF protection
- [ ] Test rate limiting
- [ ] Verify HTTPS redirect
- [ ] Check security headers
- [ ] Test password requirements
- [ ] Verify session timeout

### Automated Security Testing

**Install Security Tools:**
```bash
gem install brakeman
gem install bundler-audit
```

**Run Security Scans:**
```bash
# Run Security Copilot scanner
ruby .github/agents/security_scan.rb

# Run Brakeman
brakeman -A

# Check for vulnerable dependencies
bundle audit check --update

# Run Rails security checks
bundle exec rails_best_practices .
```

---

## Deployment Security Checklist

Before deploying to production:

- [ ] All secrets stored in environment variables
- [ ] Database credentials secured
- [ ] HTTPS enforced
- [ ] Security headers configured
- [ ] Rate limiting enabled
- [ ] Authentication implemented
- [ ] Authorization implemented
- [ ] Input validation comprehensive
- [ ] Error pages don't expose sensitive info
- [ ] Logging configured (without sensitive data)
- [ ] Backups encrypted
- [ ] Security monitoring enabled
- [ ] Dependency vulnerabilities resolved
- [ ] Security scan passed

---

## Maintenance

### Weekly
- Review security logs for suspicious activity
- Check for new security advisories

### Monthly
- Run security scans (Brakeman, bundler-audit)
- Update dependencies
- Review and update access controls

### Quarterly
- Conduct security audit
- Review and update security policies
- Penetration testing (if applicable)

---

## Resources

### Tools
- **Security Copilot**: `.github/agents/security_scan.rb`
- **Brakeman**: https://brakemanscanner.org/
- **bundler-audit**: https://github.com/rubysec/bundler-audit
- **OWASP ZAP**: https://www.zaproxy.org/

### Documentation
- **Rails Security Guide**: https://guides.rubyonrails.org/security.html
- **OWASP Top 10**: https://owasp.org/www-project-top-ten/
- **Security Copilot Docs**: `.github/agents/README.md`

### Community
- **Rails Security Mailing List**: https://groups.google.com/g/rubyonrails-security
- **Ruby Security Advisories**: https://www.ruby-lang.org/en/security/
