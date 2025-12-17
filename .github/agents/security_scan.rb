#!/usr/bin/env ruby
# frozen_string_literal: true

# Security Analysis Script
# This script performs a basic security audit of the Rails application
# Usage: ruby .github/agents/security_scan.rb

require 'pathname'

class SecurityScanner
  SECURITY_PATTERNS = {
    sql_injection: {
      pattern: /\.where\s*\(\s*["'].*#\{|\.find_by_sql\s*\(\s*["'].*#\{/,
      severity: 'HIGH',
      description: 'Potential SQL injection - use parameterized queries',
      example: 'Use: where(name: value) instead of where("name = \'#{value}\'")'
    },
    xss_vulnerability: {
      pattern: /(\.html_safe|raw\s+@)/,
      severity: 'HIGH',
      description: 'Potential XSS vulnerability - avoid html_safe and raw',
      example: 'Use: sanitize() or default escaping instead of html_safe/raw'
    },
    mass_assignment: {
      pattern: /\.new\(params\[|\.create\(params\[/,
      severity: 'CRITICAL',
      description: 'Mass assignment vulnerability - use strong parameters',
      example: 'Use: User.new(user_params) with strong parameters'
    },
    eval_usage: {
      pattern: /\beval\(/,
      severity: 'CRITICAL',
      description: 'Dangerous eval usage - avoid dynamic code execution',
      example: 'Remove eval() and use safer alternatives'
    },
    send_usage: {
      pattern: /\.send\(params|\.send\(\s*params/,
      severity: 'HIGH',
      description: 'Dangerous send with user input - avoid dynamic method calls',
      example: 'Use explicit method calls instead of send with user input'
    },
    redirect_unvalidated: {
      pattern: /redirect_to\s+params/,
      severity: 'MEDIUM',
      description: 'Unvalidated redirect - validate redirect URLs',
      example: 'Whitelist allowed redirect URLs before redirecting'
    },
    system_command: {
      pattern: /`.*params|system\(.*params|exec\(.*params/,
      severity: 'CRITICAL',
      description: 'Command injection risk - avoid executing user input',
      example: 'Never pass user input to system commands'
    }
  }.freeze

  attr_reader :findings

  def initialize
    @findings = []
    @files_scanned = 0
  end

  def scan
    puts "🔍 Security Copilot - Security Analysis"
    puts "=" * 50
    puts

    scan_ruby_files
    scan_view_files
    check_configurations
    
    display_results
  end

  private

  def scan_ruby_files
    puts "Scanning Ruby files..."
    
    ruby_files = Dir.glob([
      'app/**/*.rb',
      'lib/**/*.rb',
      'config/**/*.rb'
    ])

    ruby_files.each do |file|
      scan_file(file)
    end
  end

  def scan_view_files
    puts "Scanning view files..."
    
    view_files = Dir.glob('app/views/**/*.erb')
    
    view_files.each do |file|
      scan_file(file)
    end
  end

  def scan_file(file_path)
    return unless File.exist?(file_path)
    
    @files_scanned += 1
    content = File.read(file_path)
    
    content.each_line.with_index(1) do |line, line_number|
      SECURITY_PATTERNS.each do |name, config|
        if line =~ config[:pattern]
          @findings << {
            file: file_path,
            line: line_number,
            type: name,
            severity: config[:severity],
            description: config[:description],
            example: config[:example],
            code: line.strip
          }
        end
      end
    end
  end

  def check_configurations
    puts "Checking configurations..."
    
    # Check for force_ssl in production
    prod_config = 'config/environments/production.rb'
    if File.exist?(prod_config)
      content = File.read(prod_config)
      unless content =~ /config\.force_ssl\s*=\s*true/
        @findings << {
          file: prod_config,
          line: 0,
          type: :missing_force_ssl,
          severity: 'MEDIUM',
          description: 'HTTPS not enforced - enable force_ssl in production',
          example: 'Add: config.force_ssl = true',
          code: 'Configuration missing'
        }
      end
    end

    # Check for CSRF protection
    app_controller = 'app/controllers/application_controller.rb'
    if File.exist?(app_controller)
      content = File.read(app_controller)
      if content =~ /protect_from_forgery.*with:\s*:null_session/
        @findings << {
          file: app_controller,
          line: 0,
          type: :weak_csrf,
          severity: 'LOW',
          description: 'CSRF protection uses null_session - consider using exception',
          example: 'Use: protect_from_forgery with: :exception',
          code: 'protect_from_forgery with: :null_session'
        }
      end
    end
  end

  def display_results
    puts
    puts "=" * 50
    puts "📊 Security Scan Results"
    puts "=" * 50
    puts
    puts "Files scanned: #{@files_scanned}"
    puts "Findings: #{@findings.length}"
    puts

    if @findings.empty?
      puts "✅ No security issues detected!"
      puts
      puts "Note: This is a basic scan. For comprehensive security"
      puts "analysis, consider using:"
      puts "  - Brakeman (gem install brakeman)"
      puts "  - bundler-audit (gem install bundler-audit)"
      puts "  - RuboCop with security cops"
      return
    end

    # Group by severity
    critical = @findings.select { |f| f[:severity] == 'CRITICAL' }
    high = @findings.select { |f| f[:severity] == 'HIGH' }
    medium = @findings.select { |f| f[:severity] == 'MEDIUM' }
    low = @findings.select { |f| f[:severity] == 'LOW' }

    display_findings("🔴 CRITICAL", critical) unless critical.empty?
    display_findings("🟠 HIGH", high) unless high.empty?
    display_findings("🟡 MEDIUM", medium) unless medium.empty?
    display_findings("🟢 LOW", low) unless low.empty?

    puts
    puts "=" * 50
    puts "💡 Recommendations"
    puts "=" * 50
    puts
    puts "1. Address CRITICAL and HIGH severity issues immediately"
    puts "2. Review and fix MEDIUM severity issues"
    puts "3. Consider LOW severity issues for future improvements"
    puts "4. Run comprehensive security tools:"
    puts "   - brakeman -A"
    puts "   - bundle audit check --update"
    puts "5. Implement authentication and authorization"
    puts "6. Add comprehensive input validation"
    puts "7. Configure security headers"
    puts
  end

  def display_findings(title, findings)
    return if findings.empty?
    
    puts
    puts title
    puts "-" * 50
    
    findings.each_with_index do |finding, index|
      puts
      puts "#{index + 1}. #{finding[:description]}"
      puts "   File: #{finding[:file]}#{":#{finding[:line]}" if finding[:line] > 0}"
      puts "   Code: #{finding[:code]}"
      puts "   Fix:  #{finding[:example]}"
    end
  end
end

# Run the scanner if executed directly
if __FILE__ == $PROGRAM_NAME
  scanner = SecurityScanner.new
  scanner.scan
end
