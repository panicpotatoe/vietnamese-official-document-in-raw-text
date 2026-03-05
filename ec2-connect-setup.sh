#!/bin/bash
# Save this as: ~/ec2-connect-setup.sh
# Complete AWS EC2 SSM Connection Setup - All in One
# chmod +x ~/ec2-connect-setup.sh

set -e  # Exit on any error

# ============================================
# CONFIGURATION - Edit these variables
# ============================================

# EC2 Configuration
EC2_INSTANCE_ID="i-0c74d436efaaac47e"
EC2_REGION="ap-southeast-1"
EC2_USER="ubuntu"
EC2_IP="10.249.82.241"
EC2_PORT_WEB="8080"
EC2_PORT_FORWARD="8929"

# AWS SSO Configuration
AWS_PROFILE="vsfdp-dev"
SSO_URL="https://vingroup.awsapps.com/start/#"

# SSH Configuration
SSH_PUBLIC_KEY_PATH="$HOME/.ssh/id_rsa.pub"
SSH_PRIVATE_KEY_PATH="$HOME/.ssh/id_rsa"

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

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install it first."
        exit 1
    fi
    print_success "AWS CLI found"
    
    # Check Session Manager Plugin
    if ! command -v session-manager-plugin &> /dev/null; then
        print_error "Session Manager Plugin not found."
        echo "Install it with: brew install --cask session-manager-plugin"
        exit 1
    fi
    print_success "Session Manager Plugin found"
    
    # Check SSH keys
    if [ ! -f "$SSH_PUBLIC_KEY_PATH" ]; then
        print_error "SSH public key not found at $SSH_PUBLIC_KEY_PATH"
        exit 1
    fi
    print_success "SSH keys found"
}

# Configure AWS SSO
configure_sso() {
    print_header "Step 1: Configure AWS SSO"
    
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
    echo "  SSO Region: ap-southeast-1"
    echo "  SSO registration scopes: (press Enter for default)"
    echo ""
    read -p "Press Enter to continue..."
    
    aws configure sso --profile $AWS_PROFILE
    
    print_success "SSO configured"
}

# Login to AWS SSO
login_sso() {
    print_header "Step 2: Login to AWS SSO"
    
    print_info "Logging into AWS SSO..."
    aws sso login --profile $AWS_PROFILE
    
    print_success "SSO login complete"
}

# Push SSH public key to EC2
push_ssh_key() {
    print_header "Step 3: Push SSH Key to EC2"
    
    print_info "Reading public SSH key..."
    pubkey=$(cat $SSH_PUBLIC_KEY_PATH)
    
    # Create temporary parameters file with correct structure
    PARAMS_FILE="/tmp/ssm-params-$$.json"
    
    cat > "$PARAMS_FILE" << EOF
{
  "InstanceIds": ["$EC2_INSTANCE_ID"],
  "DocumentName": "AWS-RunShellScript",
  "Parameters": {
    "commands": [
      "mkdir -p /home/$EC2_USER/.ssh",
      "echo '$pubkey' > /home/$EC2_USER/.ssh/authorized_keys",
      "chmod 700 /home/$EC2_USER/.ssh",
      "chmod 600 /home/$EC2_USER/.ssh/authorized_keys",
      "chown -R $EC2_USER:$EC2_USER /home/$EC2_USER/.ssh"
    ]
  }
}
EOF
    
    print_info "Sending SSH key to EC2 instance via SSM..."
    
    COMMAND_ID=$(aws ssm send-command \
        --cli-input-json file://"$PARAMS_FILE" \
        --region "$EC2_REGION" \
        --profile "$AWS_PROFILE" \
        --output text \
        --query 'Command.CommandId')
    
    # Clean up
    rm -f "$PARAMS_FILE"
    
    print_success "SSH key push command sent (Command ID: $COMMAND_ID)"
    print_info "Waiting 10 seconds for command to complete..."
    sleep 10
    
    # Check command status
    STATUS=$(aws ssm get-command-invocation \
        --command-id "$COMMAND_ID" \
        --instance-id "$EC2_INSTANCE_ID" \
        --region "$EC2_REGION" \
        --profile "$AWS_PROFILE" \
        --output text \
        --query 'Status' 2>/dev/null || echo "Unknown")
    
    if [ "$STATUS" = "Success" ]; then
        print_success "SSH key successfully installed on EC2"
    else
        print_info "Command status: $STATUS (this is usually OK, verification will happen during first connection)"
    fi
}

# Setup SSH config
setup_ssh_config() {
    print_header "Step 4: Configure SSH Config"
    
    SSH_CONFIG="$HOME/.ssh/config"
    
    # Backup existing config
    if [ -f "$SSH_CONFIG" ]; then
        BACKUP_FILE="${SSH_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$SSH_CONFIG" "$BACKUP_FILE"
        print_success "Backed up existing SSH config to $BACKUP_FILE"
    fi
    
    # Check if host already exists
    if grep -q "^Host $EC2_INSTANCE_ID$" "$SSH_CONFIG" 2>/dev/null; then
        print_info "Host entry already exists in SSH config. Removing old entry..."
        # Remove old entry (on macOS, use sed -i '')
        sed -i.tmp "/^Host $EC2_INSTANCE_ID$/,/^$/d" "$SSH_CONFIG" 2>/dev/null || true
        rm -f "${SSH_CONFIG}.tmp"
    fi
    
    # Add new configuration
    cat >> "$SSH_CONFIG" << EOF

# EC2 Instance via SSM - Auto-generated on $(date)
Host $EC2_INSTANCE_ID
    User $EC2_USER
    IdentityFile $SSH_PRIVATE_KEY_PATH
    ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p' --profile $AWS_PROFILE --region $EC2_REGION"
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    
EOF
    
    print_success "SSH config updated at $SSH_CONFIG"
}

# Test connection
test_connection() {
    print_header "Step 5: Test Connection"
    
    print_info "Testing SSH connection to EC2 instance..."
    echo ""
    echo "Attempting to connect to: $EC2_INSTANCE_ID"
    echo "If this is your first connection, it may take a moment..."
    echo ""
    
    read -p "Do you want to test the connection now? (y/n): " test_now
    
    if [[ "$test_now" =~ ^[Yy]$ ]]; then
        ssh -o ConnectTimeout=10 $EC2_INSTANCE_ID "echo 'Connection successful!' && hostname && whoami" || {
            print_error "Connection test failed"
            echo ""
            echo "Troubleshooting tips:"
            echo "1. Make sure SSM Agent is running on the EC2 instance"
            echo "2. Verify the instance has the AmazonSSMManagedInstanceCore policy"
            echo "3. Try manually: ssh $EC2_INSTANCE_ID"
            return 1
        }
        print_success "Connection test passed!"
    else
        print_info "Skipping connection test"
    fi
}

# Create connection helper script
create_connect_script() {
    print_header "Creating Connection Helper Script"
    
    CONNECT_SCRIPT="$HOME/connect-ec2.sh"
    
    cat > "$CONNECT_SCRIPT" << 'EOF'
#!/bin/bash
# Quick connect to EC2 instance

EC2_INSTANCE_ID="INSTANCE_ID_PLACEHOLDER"
AWS_PROFILE="PROFILE_PLACEHOLDER"

# Check if SSO session is valid
if ! aws sts get-caller-identity --profile $AWS_PROFILE &> /dev/null; then
    echo "🔐 SSO session expired. Logging in..."
    aws sso login --profile $AWS_PROFILE
fi

echo "🚀 Connecting to EC2 instance..."
ssh $EC2_INSTANCE_ID
EOF
    
    # Replace placeholders
    sed -i.tmp "s/INSTANCE_ID_PLACEHOLDER/$EC2_INSTANCE_ID/g" "$CONNECT_SCRIPT"
    sed -i.tmp "s/PROFILE_PLACEHOLDER/$AWS_PROFILE/g" "$CONNECT_SCRIPT"
    rm -f "${CONNECT_SCRIPT}.tmp"
    
    chmod +x "$CONNECT_SCRIPT"
    
    print_success "Connection helper script created at: $CONNECT_SCRIPT"
}

# Print summary
print_summary() {
    print_header "Setup Complete!"
    
    echo ""
    echo "Configuration Summary:"
    echo "  Instance ID: $EC2_INSTANCE_ID"
    echo "  Region: $EC2_REGION"
    echo "  Profile: $AWS_PROFILE"
    echo "  User: $EC2_USER"
    echo ""
    echo "To connect to your EC2 instance, use either:"
    echo ""
    echo "  Option 1 (Quick script):"
    echo "    ~/connect-ec2.sh"
    echo ""
    echo "  Option 2 (Direct SSH):"
    echo "    ssh $EC2_INSTANCE_ID"
    echo ""
    echo "  Option 3 (Direct SSH with port forwarding):"
    echo "    ssh -L $EC2_PORT_WEB:localhost:$EC2_PORT_FORWARD $EC2_INSTANCE_ID"
    echo "    (then access GitLab UI with http://localhost:$EC2_PORT_WEB)"
    echo ""
    echo "If your SSO session expires, login again with:"
    echo "    aws sso login --profile $AWS_PROFILE"
    echo ""
}

# ============================================
# MAIN EXECUTION
# ============================================

main() {
    echo "╔════════════════════════════════════════════╗"
    echo "║   AWS EC2 SSM Connection Setup Script      ║"
    echo "╚════════════════════════════════════════════╝"
    
    check_prerequisites
    configure_sso
    login_sso
    push_ssh_key
    setup_ssh_config
    create_connect_script
    test_connection
    print_summary
}

# Run main function
main