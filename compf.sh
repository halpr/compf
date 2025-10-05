#!/bin/bash
#
# Orgf - File Organizer
# Author: Filipe Soares
# GitHub: https://github.com/halpr
# License: MIT
# Version: 1.0.0
# Description: Compf - This scipt is for comparing files with GPG keys.
#
#!/bin/bash

# Colors and styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'

# Unicode characters
CHECK="✓"
CROSS="✗"
ARROW="→"
LOCK="🔒"
KEY="🔑"
FILE="📄"
SHIELD="🛡️"
WARNING="⚠️"

# Clear screen and show banner
clear
print_banner() {
    echo -e "${MAGENTA}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║       ${CYAN}${SHIELD} GPG SIGNATURE VERIFICATION TOOL ${LOCK}${MAGENTA}          ║"
    echo "║                                                           ║"
    echo "║           ${WHITE}Verify File Authenticity & Integrity${MAGENTA}          ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

# Animated loading spinner
spinner() {
    local pid=$1
    local msg=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "\r${CYAN}${spin:$i:1}${RESET} ${msg}"
        sleep 0.1
    done
    printf "\r${GREEN}${CHECK}${RESET} ${msg}\n"
}

# Print styled box
print_box() {
    local color=$1
    local title=$2
    local content=$3
    
    echo -e "${color}┌─────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${color}│${RESET} ${BOLD}${title}${RESET}"
    echo -e "${color}├─────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${content}"
    echo -e "${color}└─────────────────────────────────────────────────────────┘${RESET}"
}

# Print success message
print_success() {
    echo -e "\n${BG_GREEN}${WHITE}${BOLD} ${CHECK} VERIFIED ${RESET}${GREEN} $1 ${RESET}\n"
}

# Print error message
print_error() {
    echo -e "\n${BG_RED}${WHITE}${BOLD} ${CROSS} FAILED ${RESET}${RED} $1 ${RESET}\n"
}

# Print warning message
print_warning() {
    echo -e "\n${BG_YELLOW}${WHITE}${BOLD} ${WARNING} WARNING ${RESET}${YELLOW} $1 ${RESET}\n"
}

# Print info message
print_info() {
    echo -e "${CYAN}${ARROW}${RESET} ${WHITE}$1${RESET}"
}

# Check if GPG is installed
check_gpg() {
    if ! command -v gpg &> /dev/null; then
        print_error "GPG is not installed on this system"
        echo -e "${YELLOW}Please install GPG:${RESET}"
        echo -e "  • Ubuntu/Debian: ${CYAN}sudo apt install gnupg${RESET}"
        echo -e "  • macOS: ${CYAN}brew install gnupg${RESET}"
        echo -e "  • Fedora: ${CYAN}sudo dnf install gnupg${RESET}"
        exit 1
    fi
}

# Verify GPG signature
verify_signature() {
    local file=$1
    local sig_file=$2
    
    # Check if files exist
    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        return 1
    fi
    
    if [[ ! -f "$sig_file" ]]; then
        print_error "Signature file not found: $sig_file"
        return 1
    fi
    
    # Get file info
    local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    local size_human=$(numfmt --to=iec-i --suffix=B $size 2>/dev/null || echo "$size bytes")
    
    print_info "File: $(basename "$file")"
    print_info "Size: $size_human"
    print_info "Signature: $(basename "$sig_file")"
    echo ""
    
    print_info "Verifying GPG signature..."
    echo ""
    
    # Capture GPG output
    local gpg_output=$(gpg --verify "$sig_file" "$file" 2>&1)
    local gpg_status=$?
    
    # Extract key information
    local key_id=$(echo "$gpg_output" | grep -oE 'key [A-F0-9]+' | awk '{print $2}' | head -1)
    local fingerprint=$(echo "$gpg_output" | grep -oE 'fingerprint: [A-F0-9 ]+' | cut -d: -f2 | xargs)
    local signer=$(echo "$gpg_output" | grep -oE '"[^"]+"' | head -1 | tr -d '"')
    local timestamp=$(echo "$gpg_output" | grep -oE '[A-Z][a-z]{2} [A-Z][a-z]{2} [0-9 :]+ [0-9]{4}' | head -1)
    
    # Check if signature is good
    if echo "$gpg_output" | grep -q "Good signature"; then
        print_success "Signature is VALID!"
        
        local content="${GREEN}│${RESET} ${BOLD}${SHIELD} Signature Status:${RESET} ${GREEN}Valid & Trusted${RESET}\n"
        content+="${GREEN}│${RESET}\n"
        
        if [[ -n "$signer" ]]; then
            content+="${GREEN}│${RESET} ${BOLD}Signed by:${RESET} $signer\n"
        fi
        
        if [[ -n "$key_id" ]]; then
            content+="${GREEN}│${RESET} ${BOLD}Key ID:${RESET} ${CYAN}$key_id${RESET}\n"
        fi
        
        if [[ -n "$fingerprint" ]]; then
            content+="${GREEN}│${RESET} ${BOLD}Fingerprint:${RESET}\n"
            content+="${GREEN}│${RESET} ${CYAN}$fingerprint${RESET}\n"
        fi
        
        if [[ -n "$timestamp" ]]; then
            content+="${GREEN}│${RESET}\n"
            content+="${GREEN}│${RESET} ${BOLD}Signed on:${RESET} $timestamp\n"
        fi
        
        content+="${GREEN}│${RESET}\n"
        content+="${GREEN}│${RESET} ${BOLD}File Integrity:${RESET} ${GREEN}Confirmed ${CHECK}${RESET}\n"
        content+="${GREEN}│${RESET} ${BOLD}Authenticity:${RESET} ${GREEN}Verified ${CHECK}${RESET}"
        
        print_box "$GREEN" "${SHIELD} VERIFICATION SUCCESSFUL" "$content"
        
        # Check if key is trusted
        if echo "$gpg_output" | grep -qi "WARNING"; then
            print_warning "Key is not in your trusted keyring"
            echo -e "${YELLOW}This doesn't mean the signature is invalid, but you should verify"
            echo -e "the key fingerprint with the official source.${RESET}\n"
        fi
        
        return 0
    else
        print_error "Signature verification FAILED!"
        
        local content="${RED}│${RESET} ${BOLD}${CROSS} Signature Status:${RESET} ${RED}INVALID${RESET}\n"
        content+="${RED}│${RESET}\n"
        
        if echo "$gpg_output" | grep -q "BAD signature"; then
            content+="${RED}│${RESET} ${RED}${BOLD}BAD SIGNATURE DETECTED!${RESET}\n"
            content+="${RED}│${RESET}\n"
            content+="${RED}│${RESET} This file may have been:\n"
            content+="${RED}│${RESET}   • Tampered with\n"
            content+="${RED}│${RESET}   • Corrupted during download\n"
            content+="${RED}│${RESET}   • Modified after signing\n"
            content+="${RED}│${RESET}\n"
            content+="${RED}│${RESET} ${BOLD}${WARNING} DO NOT USE THIS FILE!${RESET}"
        elif echo "$gpg_output" | grep -q "no public key"; then
            local missing_key=$(echo "$gpg_output" | grep -oE 'key [A-F0-9]+' | awk '{print $2}')
            content+="${RED}│${RESET} ${YELLOW}Public key not found in keyring${RESET}\n"
            content+="${RED}│${RESET}\n"
            if [[ -n "$missing_key" ]]; then
                content+="${RED}│${RESET} ${BOLD}Required Key ID:${RESET} ${CYAN}$missing_key${RESET}\n"
                content+="${RED}│${RESET}\n"
            fi
            content+="${RED}│${RESET} Import the signing key first:\n"
            content+="${RED}│${RESET} ${CYAN}gpg --keyserver keyserver.ubuntu.com --recv-keys <KEY_ID>${RESET}"
        else
            content+="${RED}│${RESET} Unknown verification error\n"
            content+="${RED}│${RESET}\n"
            content+="${RED}│${RESET} Check:\n"
            content+="${RED}│${RESET}   • Signature file format\n"
            content+="${RED}│${RESET}   • File and signature match\n"
            content+="${RED}│${RESET}   • GPG keyring has correct key"
        fi
        
        print_box "$RED" "${CROSS} VERIFICATION FAILED" "$content"
        
        return 1
    fi
}

# Verify with detached signature
verify_with_detached_sig() {
    echo -e "${BOLD}${MAGENTA}${SHIELD} DETACHED SIGNATURE VERIFICATION${RESET}\n"
    
    echo -ne "${CYAN}Enter path to file (e.g., ubuntu.iso):${RESET} "
    read -r file
    
    echo -ne "${CYAN}Enter path to signature file (e.g., ubuntu.iso.sig or .asc):${RESET} "
    read -r sig_file
    
    echo ""
    verify_signature "$file" "$sig_file"
}

# Import GPG key
import_key() {
    echo -e "${BOLD}${MAGENTA}${KEY} IMPORT GPG PUBLIC KEY${RESET}\n"
    
    echo -e "${CYAN}Choose import method:${RESET}"
    echo -e "  ${YELLOW}1)${RESET} Import from file"
    echo -e "  ${YELLOW}2)${RESET} Import from keyserver by ID"
    echo -e "  ${YELLOW}3)${RESET} Import from keyserver by fingerprint"
    echo ""
    echo -ne "${BOLD}${CYAN}Enter choice [1-3]:${RESET} "
    read -r method
    
    case $method in
        1)
            echo -ne "${CYAN}Enter path to key file:${RESET} "
            read -r keyfile
            
            if [[ ! -f "$keyfile" ]]; then
                print_error "Key file not found: $keyfile"
                return 1
            fi
            
            print_info "Importing key from file..."
            gpg --import "$keyfile"
            ;;
        2)
            echo -ne "${CYAN}Enter key ID (e.g., 46181433FBB75451):${RESET} "
            read -r keyid
            
            print_info "Fetching key from keyserver..."
            gpg --keyserver keyserver.ubuntu.com --recv-keys "$keyid"
            ;;
        3)
            echo -ne "${CYAN}Enter fingerprint:${RESET} "
            read -r fingerprint
            
            print_info "Fetching key from keyserver..."
            gpg --keyserver keyserver.ubuntu.com --recv-keys "$fingerprint"
            ;;
        *)
            print_error "Invalid choice"
            return 1
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        print_success "Key imported successfully!"
    else
        print_error "Failed to import key"
    fi
}

# List GPG keys
list_keys() {
    echo -e "${BOLD}${MAGENTA}${KEY} GPG PUBLIC KEYS IN KEYRING${RESET}\n"
    
    print_info "Listing all public keys..."
    echo ""
    
    gpg --list-keys --keyid-format LONG
    
    echo ""
}

# Main menu
show_menu() {
    echo -e "${BOLD}${BLUE}What would you like to do?${RESET}\n"
    echo -e "  ${YELLOW}1)${RESET} ${SHIELD}  Verify file with GPG signature"
    echo -e "  ${YELLOW}2)${RESET} ${KEY}  Import GPG public key"
    echo -e "  ${YELLOW}3)${RESET} ${FILE}  List GPG keys in keyring"
    echo -e "  ${YELLOW}4)${RESET} ${CROSS}  Exit\n"
    echo -ne "${BOLD}${CYAN}Enter your choice [1-4]:${RESET} "
}

# Main script
print_banner
check_gpg

while true; do
    show_menu
    read -r choice
    
    case $choice in
        1)
            echo ""
            verify_with_detached_sig
            
            echo -e "\n${DIM}Press Enter to continue...${RESET}"
            read -r
            clear
            print_banner
            ;;
        2)
            echo ""
            import_key
            
            echo -e "\n${DIM}Press Enter to continue...${RESET}"
            read -r
            clear
            print_banner
            ;;
        3)
            echo ""
            list_keys
            
            echo -e "\n${DIM}Press Enter to continue...${RESET}"
            read -r
            clear
            print_banner
            ;;
        4)
            echo ""
            echo -e "${GREEN}${BOLD}Stay secure! ${SHIELD}${RESET}\n"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please try again.${RESET}\n"
            sleep 1
            ;;
    esac
done
