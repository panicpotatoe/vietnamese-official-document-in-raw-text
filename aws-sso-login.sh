#!/bin/bash
# Save this as: ~/aws-sso-login.sh
# AWS SSO Configuration and Login
# chmod +x ~/aws-sso-login.sh

set -e

# ============================================
# CONFIGURATION
# ============================================
AWS_PROFILE="vsfdp-dev"
SSO_URL="https://vingroup.awsapps.com/start/#"
SSO_REGION="ap-southeast-1"

# ============================================
# FUNCTIONS
# ============================================

print_header() {
    echo ""
    echo "========================================="
    echo "$1"
    echo "========================================="
}

print_success() {
    echo "✓ $1"
}

print_info() {
    echo "ℹ️  $1"
}

print_error() {
    echo "❌ $1"
}

check_prerequisites() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install it first."
        exit 1
    fi
}

configure_sso() {
    print_header "Configure AWS SSO"
    
    # Check if profile already exists
    if aws configure list --profile $AWS_PROFILE &> /dev/null; then
        print_info "SSO profile '$AWS_PROFILE' already exists"
        read -p "Do you want to reconfigure it? (y/n): " reconfigure
        if [[ ! "$reconfigure" =~ ^[Yy]$ ]]; then
            print_success "Skipping SSO configuration"
            return
        fi
    fi
    
    print_info "Starting interactive SSO configuration..."
    echo ""
    echo "When prompted, enter these values:"
    echo "  SSO session name: $AWS_PROFILE"
    echo "  SSO start URL: $SSO_URL"
    echo "  SSO Region: $SSO_REGION"
    echo "  SSO registration scopes: (press Enter for default)"
    echo ""
    read -p "Press Enter to continue..."
    
    aws configure sso --profile $AWS_PROFILE
    
    print_success "SSO configured"
}

login_sso() {
    print_header "Login to AWS SSO"
    
    print_info "Logging into AWS SSO..."
    aws sso login --profile $AWS_PROFILE
    
    print_success "SSO login complete"
}

main() {
    echo "╔════════════════════════════════════════════╗"
    echo "║        AWS SSO Login Helper Script         ║"
    echo "╚════════════════════════════════════════════╝"
    
    check_prerequisites
    configure_sso
    login_sso
}

main
