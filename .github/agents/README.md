# Security Copilot Agent

A specialized AI agent designed to help maintain and improve the security posture of this Rails application.

## Overview

The Security Copilot Agent is a custom GitHub Copilot agent that specializes in:
- Security code reviews
- Vulnerability detection
- Secure coding best practices
- Rails-specific security patterns
- OWASP compliance

## Features

### 🔍 Automated Security Reviews
The agent automatically reviews code changes for common security vulnerabilities including:
- SQL Injection
- Cross-Site Scripting (XSS)
- Cross-Site Request Forgery (CSRF)
- Mass Assignment vulnerabilities
- Insecure Direct Object References
- Sensitive Data Exposure
- Missing Authorization checks

### 🛡️ Security Best Practices
Enforces security best practices such as:
- Strong parameter usage
- Input validation
- Output sanitization
- Secure session management
- Proper authentication and authorization
- Secure password storage
- Security header configuration

### 📚 Educational Guidance
Provides:
- Clear explanations of security issues
- Impact analysis
- Actionable remediation steps
- Code examples
- References to security standards (OWASP, CWE)

## Usage

### For Code Reviews
When reviewing pull requests, invoke the Security Copilot Agent to:
1. Identify potential security vulnerabilities
2. Suggest secure coding patterns
3. Verify compliance with security best practices

### For Development
During development, consult the agent for:
- Security design decisions
- Implementation guidance for security features
- Vulnerability remediation
- Security testing strategies

## Agent Capabilities

The Security Copilot Agent can help with:

### Authentication & Authorization
- Implementing secure user authentication
- Adding authorization checks
- Session management
- Password security

### Input Validation
- Model validations
- Strong parameters
- Data sanitization
- File upload security

### Output Security
- XSS prevention
- Safe HTML rendering
- JSON API security
- Template security

### Database Security
- SQL injection prevention
- Secure queries
- Data encryption
- Secure migrations

### Configuration Security
- Security headers
- HTTPS enforcement
- Secure cookie settings
- Environment variable management

## Security Checklist

Use this checklist when reviewing code:

- [ ] All user input is validated at the model level
- [ ] Strong parameters are used for mass assignment
- [ ] Authorization is implemented for all sensitive actions
- [ ] No SQL injection vulnerabilities present
- [ ] XSS prevention measures are in place
- [ ] CSRF protection is enabled
- [ ] Sensitive data is not logged or exposed
- [ ] Security headers are properly configured
- [ ] Dependencies are up to date
- [ ] Secrets are stored securely
- [ ] File uploads are validated
- [ ] Rate limiting is implemented where needed

## Common Vulnerabilities Reference

### SQL Injection
**Vulnerable:**
```ruby
User.where("name = '#{params[:name]}'")
```

**Secure:**
```ruby
User.where(name: params[:name])
```

### Cross-Site Scripting (XSS)
**Vulnerable:**
```erb
<%= raw @user.comment %>
<%= @user.comment.html_safe %>
```

**Secure:**
```erb
<%= @user.comment %>
<!-- Or, if HTML is needed: -->
<%= sanitize @user.comment, tags: %w(p br strong em) %>
```

### Mass Assignment
**Vulnerable (Rails 3):**
```ruby
User.new(params[:user])
```

**Secure (Rails 4+):**
```ruby
User.new(user_params)

private

def user_params
  params.require(:user).permit(:name, :email)
end
```

### Insecure Direct Object Reference
**Vulnerable:**
```ruby
def show
  @user = User.find(params[:id])
end
```

**Secure:**
```ruby
def show
  @user = User.find(params[:id])
  authorize @user # Using Pundit
  # OR
  unless current_user == @user || current_user.admin?
    redirect_to root_path, alert: 'Access denied'
  end
end
```

## Integration

### With GitHub Copilot
The agent integrates with GitHub Copilot to provide security-focused assistance directly in your development environment.

### With CI/CD
Recommendations for CI/CD integration:
- Add Brakeman for static security analysis
- Use bundler-audit for dependency vulnerability scanning
- Implement security testing in your test suite
- Add security linting to your pipeline

## Best Practices for This Application

### Current Security Gaps
The demo application currently has several security gaps:
1. **No Authentication**: Users can be created/edited/deleted without authentication
2. **No Authorization**: Any user can modify any user or micropost
3. **Limited Validation**: Models have minimal input validation
4. **No Security Headers**: Production environment lacks security headers
5. **No Rate Limiting**: API endpoints are not rate-limited

### Recommended Improvements
1. Add authentication (consider Devise gem)
2. Implement authorization (consider Pundit or CanCanCan)
3. Add comprehensive model validations
4. Configure security headers (use secure_headers gem)
5. Implement rate limiting (use rack-attack gem)
6. Add HTTPS enforcement in production
7. Implement CAPTCHA for public forms
8. Add security monitoring and logging

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [Brakeman Scanner](https://brakemanscanner.org/)
- [bundler-audit](https://github.com/rubysec/bundler-audit)
- [Rails Security Checklist](https://github.com/eliotsykes/rails-security-checklist)

## Contributing

To improve the Security Copilot Agent:
1. Update the agent configuration in `.github/agents/security-copilot.md`
2. Add new security patterns and examples
3. Update the security checklist
4. Document new security best practices

## License

This agent configuration is part of the demo_app repository.
