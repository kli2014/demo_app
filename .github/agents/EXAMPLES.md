# Security Copilot Agent - Demonstration

This document demonstrates the capabilities of the Security Copilot Agent.

## Example 1: Detecting SQL Injection Vulnerability

### Vulnerable Code
```ruby
# app/controllers/users_controller.rb
def search
  @users = User.where("name = '#{params[:name]}'")
end
```

### Security Copilot Analysis
**Issue:** SQL Injection Vulnerability (CRITICAL)

**Explanation:** The code uses string interpolation in a SQL WHERE clause, allowing attackers to inject malicious SQL code through the `name` parameter.

**Attack Example:**
```
?name=' OR '1'='1
```
This would result in: `WHERE name = '' OR '1'='1'` returning all users.

**Fix:**
```ruby
def search
  @users = User.where(name: params[:name])
  # OR
  @users = User.where("name = ?", params[:name])
end
```

---

## Example 2: Detecting XSS Vulnerability

### Vulnerable Code
```erb
<!-- app/views/microposts/show.html.erb -->
<div class="content">
  <%= raw @micropost.content %>
</div>
```

### Security Copilot Analysis
**Issue:** Cross-Site Scripting (XSS) Vulnerability (HIGH)

**Explanation:** Using `raw` or `html_safe` renders content without escaping, allowing malicious JavaScript to execute.

**Attack Example:**
If a micropost contains:
```
<script>alert('XSS Attack!');</script>
```
It will execute in the victim's browser.

**Fix:**
```erb
<!-- Default - Safe, escaped automatically -->
<div class="content">
  <%= @micropost.content %>
</div>

<!-- If HTML formatting is needed -->
<div class="content">
  <%= sanitize @micropost.content, tags: %w(p br strong em), attributes: %w() %>
</div>
```

---

## Example 3: Detecting Mass Assignment Vulnerability

### Vulnerable Code
```ruby
# app/controllers/users_controller.rb (Rails 3 style)
def create
  @user = User.new(params[:user])
  if @user.save
    redirect_to @user
  else
    render :new
  end
end
```

### Security Copilot Analysis
**Issue:** Mass Assignment Vulnerability (CRITICAL in Rails 3, Mitigated in Rails 4+)

**Explanation:** In Rails 3, this allows attackers to set any attribute, including admin flags or other sensitive fields.

**Attack Example:**
```
POST /users
user[name]=Attacker&user[email]=attacker@evil.com&user[admin]=true
```

**Fix (Rails 4+ - Already Implemented in Demo App):**
```ruby
def create
  @user = User.new(user_params)
  if @user.save
    redirect_to @user, notice: 'User was successfully created.'
  else
    render :new
  end
end

private

def user_params
  params.require(:user).permit(:name, :email)
end
```

---

## Example 4: Detecting Insecure Direct Object Reference

### Vulnerable Code
```ruby
# app/controllers/microposts_controller.rb
def destroy
  @micropost = Micropost.find(params[:id])
  @micropost.destroy
  redirect_to microposts_url
end
```

### Security Copilot Analysis
**Issue:** Insecure Direct Object Reference (HIGH)

**Explanation:** Any user can delete any micropost by manipulating the ID in the URL.

**Attack Example:**
```
DELETE /microposts/123
```
An attacker can delete micropost #123 even if they don't own it.

**Fix:**
```ruby
def destroy
  @micropost = current_user.microposts.find(params[:id])
  # OR with Pundit
  @micropost = Micropost.find(params[:id])
  authorize @micropost
  
  @micropost.destroy
  redirect_to microposts_url
end
```

---

## Example 5: Security Configuration Issues

### Missing Configuration
```ruby
# config/environments/production.rb
# Missing force_ssl configuration
```

### Security Copilot Analysis
**Issue:** HTTPS Not Enforced (MEDIUM)

**Explanation:** Without forcing SSL, sensitive data (passwords, session tokens) can be transmitted over insecure HTTP connections.

**Fix:**
```ruby
# config/environments/production.rb
DemoApp::Application.configure do
  # Force all access to the app over SSL
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

## Example 6: Missing Input Validation

### Current Code
```ruby
# app/models/user.rb
class User < ActiveRecord::Base
  has_many :microposts
end
```

### Security Copilot Analysis
**Issue:** Missing Input Validation (MEDIUM)

**Explanation:** Without validation, invalid or malicious data can be stored in the database.

**Recommended Fix:**
```ruby
# app/models/user.rb
class User < ActiveRecord::Base
  has_many :microposts, dependent: :destroy
  
  # Presence validation
  validates :name, presence: true, 
                   length: { minimum: 2, maximum: 50 }
  
  # Email validation
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    length: { maximum: 255 },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  
  # Normalize email before saving
  before_save :downcase_email
  
  private
  
  def downcase_email
    self.email = email.downcase
  end
end
```

---

## Running the Security Scanner

```bash
$ ruby .github/agents/security_scan.rb

🔍 Security Copilot - Security Analysis
==================================================

Scanning Ruby files...
Scanning view files...
Checking configurations...

==================================================
📊 Security Scan Results
==================================================

Files scanned: 33
Findings: 0

✅ No security issues detected!
```

---

## Real-World Example: Complete Secure Controller

### Before (Insecure)
```ruby
class MicropostsController < ApplicationController
  def index
    @microposts = Micropost.all
  end
  
  def show
    @micropost = Micropost.find(params[:id])
  end
  
  def create
    @micropost = Micropost.new(params[:micropost])
    if @micropost.save
      redirect_to @micropost
    else
      render :new
    end
  end
  
  def destroy
    @micropost = Micropost.find(params[:id])
    @micropost.destroy
    redirect_to microposts_url
  end
end
```

### After (Secure)
```ruby
class MicropostsController < ApplicationController
  # Require authentication
  before_action :authenticate_user!
  
  # Set micropost and authorize
  before_action :set_micropost, only: [:show, :edit, :update, :destroy]
  before_action :authorize_micropost, only: [:edit, :update, :destroy]
  
  # Verify authorization was called
  after_action :verify_authorized, except: [:index, :new, :create]
  
  def index
    # Paginate to prevent DoS
    @microposts = Micropost.order(created_at: :desc).page(params[:page])
  end
  
  def show
    authorize @micropost
  end
  
  def create
    @micropost = current_user.microposts.build(micropost_params)
    
    if @micropost.save
      redirect_to @micropost, notice: 'Micropost was successfully created.'
    else
      render :new
    end
  end
  
  def destroy
    @micropost.destroy
    redirect_to microposts_url, notice: 'Micropost was successfully deleted.'
  end
  
  private
  
  def set_micropost
    @micropost = Micropost.find(params[:id])
  end
  
  def authorize_micropost
    authorize @micropost
  end
  
  # Strong parameters - prevent mass assignment
  def micropost_params
    params.require(:micropost).permit(:content)
  end
end
```

---

## Summary

The Security Copilot Agent helps identify and fix:

1. **SQL Injection** - Use parameterized queries
2. **XSS Vulnerabilities** - Use default escaping or sanitize
3. **Mass Assignment** - Use strong parameters
4. **Insecure Direct Object References** - Implement authorization
5. **Missing HTTPS** - Force SSL in production
6. **Missing Validation** - Add comprehensive model validations
7. **Missing Authentication** - Use Devise or similar
8. **Missing Authorization** - Use Pundit or CanCanCan

For more information, see:
- `.github/agents/security-copilot.md` - Full agent documentation
- `.github/agents/QUICK_REFERENCE.md` - Quick reference guide
- `.github/agents/README.md` - Overview and features
