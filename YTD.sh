#!/bin/bash

# YouTube Video/Audio Downloader with format selection
# Requires: yt-dlp, ffmpeg (for audio conversion)

# Set colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_menu() {
    echo -e "${PURPLE}[MENU]${NC} $1"
}

# Check if yt-dlp is installed
check_dependencies() {
    if ! command -v yt-dlp &> /dev/null; then
        print_error "yt-dlp is not installed. Please install it first."
        print_step "You can install it with: sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && sudo chmod a+rx /usr/local/bin/yt-dlp"
        exit 1
    fi
    
    if ! command -v ffmpeg &> /dev/null; then
        print_warning "ffmpeg is not installed. Some format conversions may not work properly."
    fi
}

# Function to display help
show_help() {
    echo "Usage: $0"
    echo
    echo "This script will prompt you for a YouTube URL and show available video formats."
    echo
    echo "Dependencies:"
    echo "  yt-dlp - YouTube video downloader"
    echo "  ffmpeg - Audio conversion (optional but recommended)"
    echo
    echo "Examples of installation:"
    echo "  yt-dlp: sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && sudo chmod a+rx /usr/local/bin/yt-dlp"
    echo "  ffmpeg: sudo apt install ffmpeg"
}

# Function to get video title
get_video_title() {
    yt-dlp --get-title "$URL" 2>/dev/null | head -1
}

# Function to list available video formats with size information
list_video_formats() {
    print_step "Fetching available video formats for $URL..."
    echo
    
    # Get video title
    local title=$(get_video_title)
    echo -e "${CYAN}Video:${NC} $title"
    echo
    
    # Get available video formats
    local formats=$(yt-dlp --list-formats "$URL" 2>/dev/null)
    
    # Extract video-only formats with size information
    echo -e "${CYAN}Available video formats:${NC}"
    echo "----------------------------------------------------------------------------"
    printf "%-6s %-8s %-12s %-10s %-10s %s\n" "ID" "EXT" "RESOLUTION" "FPS" "SIZE" "NOTE"
    echo "----------------------------------------------------------------------------"
    
    # Parse and display video formats
    echo "$formats" | grep -E "video only|images only" | while read -r line; do
        # Extract format information
        format_id=$(echo "$line" | awk '{print $1}')
        extension=$(echo "$line" | awk '{print $2}')
        resolution=$(echo "$line" | awk '{print $3}')
        fps=$(echo "$line" | awk '{print $4}')
        size=$(echo "$line" | awk '{
            for(i=1;i<=NF;i++) {
                if ($i ~ /^[0-9.]+(MiB|KiB|GiB)$/) {
                    print $i
                    break
                }
            }
        }')
        note=$(echo "$line" | awk '{
            for(i=1;i<=NF;i++) {
                if ($i ~ /^[0-9.]+(MiB|KiB|GiB)$/) {
                    for(j=i+1;j<=NF;j++) printf $j " "
                    break
                }
            }
        }')
        
        # If size is not available, try to get it from the format list
        if [ -z "$size" ]; then
            size=$(yt-dlp --get-format "$format_id" "$URL" 2>/dev/null | grep -oE "[0-9.]+(MiB|KiB|GiB)" | head -1)
        fi
        
        # Format the output
        printf "%-6s %-8s %-12s %-10s %-10s %s\n" "$format_id" "$extension" "$resolution" "$fps" "$size" "$note"
    done
    
    # Show combined formats (video + audio)
    echo
    echo -e "${CYAN}Combined formats (video + audio):${NC}"
    echo "----------------------------------------------------------------------------"
    printf "%-6s %-8s %-12s %-10s %-10s %s\n" "ID" "EXT" "RESOLUTION" "FPS" "SIZE" "NOTE"
    echo "----------------------------------------------------------------------------"
    
    echo "$formats" | grep -vE "video only|audio only|images only" | while read -r line; do
        # Extract format information
        format_id=$(echo "$line" | awk '{print $1}')
        extension=$(echo "$line" | awk '{print $2}')
        resolution=$(echo "$line" | awk '{print $3}')
        fps=$(echo "$line" | awk '{print $4}')
        size=$(echo "$line" | awk '{
            for(i=1;i<=NF;i++) {
                if ($i ~ /^[0-9.]+(MiB|KiB|GiB)$/) {
                    print $i
                    break
                }
            }
        }')
        note=$(echo "$line" | awk '{
            for(i=1;i<=NF;i++) {
                if ($i ~ /^[0-9.]+(MiB|KiB|GiB)$/) {
                    for(j=i+1;j<=NF;j++) printf $j " "
                    break
                }
            }
        }')
        
        # If size is not available, try to get it from the format list
        if [ -z "$size" ]; then
            size=$(yt-dlp --get-format "$format_id" "$URL" 2>/dev/null | grep -oE "[0-9.]+(MiB|KiB|GiB)" | head -1)
        fi
        
        # Format the output
        printf "%-6s %-8s %-12s %-10s %-10s %s\n" "$format_id" "$extension" "$resolution" "$fps" "$size" "$note"
    done
    
    # Show audio-only formats
    echo
    echo -e "${CYAN}Audio-only formats:${NC}"
    echo "----------------------------------------------------------------------------"
    printf "%-6s %-8s %-12s %-10s %s\n" "ID" "EXT" "BITRATE" "SIZE" "NOTE"
    echo "----------------------------------------------------------------------------"
    
    echo "$formats" | grep "audio only" | while read -r line; do
        # Extract format information
        format_id=$(echo "$line" | awk '{print $1}')
        extension=$(echo "$line" | awk '{print $2}')
        bitrate=$(echo "$line" | awk '{print $3}')
        size=$(echo "$line" | awk '{
            for(i=1;i<=NF;i++) {
                if ($i ~ /^[0-9.]+(MiB|KiB|GiB)$/) {
                    print $i
                    break
                }
            }
        }')
        note=$(echo "$line" | awk '{
            for(i=1;i<=NF;i++) {
                if ($i ~ /^[0-9.]+(MiB|KiB|GiB)$/) {
                    for(j=i+1;j<=NF;j++) printf $j " "
                    break
                }
            }
        }')
        
        # If size is not available, try to get it from the format list
        if [ -z "$size" ]; then
            size=$(yt-dlp --get-format "$format_id" "$URL" 2>/dev/null | grep -oE "[0-9.]+(MiB|KiB|GiB)" | head -1)
        fi
        
        # Format the output
        printf "%-6s %-8s %-12s %-10s %s\n" "$format_id" "$extension" "$bitrate" "$size" "$note"
    done
}

# Function to download selected format
download_format() {
    local format_id=$1
    local output_dir=${2:-"."}
    
    print_step "Downloading format $format_id..."
    
    # Create output directory if it doesn't exist
    if [[ ! -d "$output_dir" ]]; then
        mkdir -p "$output_dir"
    fi
    
    # Download the selected format
    yt-dlp -f "$format_id" -o "$output_dir/%(title)s.%(ext)s" "$URL"
    
    if [[ $? -eq 0 ]]; then
        print_status "Download completed successfully!"
    else
        print_error "Download failed"
        exit 1
    fi
}

# Function to prompt for URL
get_url() {
    echo
    print_menu "Please enter the YouTube URL:"
    read -r URL
    
    if [[ -z "$URL" ]]; then
        print_error "No URL provided. Exiting."
        exit 1
    fi
    
    # Validate URL format
    if [[ ! "$URL" =~ ^https?://(www\.)?(youtube\.com|youtu\.be) ]]; then
        print_warning "This doesn't look like a standard YouTube URL. Continue anyway? (y/N)"
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to prompt for output directory
get_output_dir() {
    echo
    print_menu "Enter output directory (default: current directory):"
    read -r output_dir
    
    if [[ -z "$output_dir" ]]; then
        output_dir="."
    fi
    
    echo "$output_dir"
}

# Function to prompt for format selection
get_format_selection() {
    echo
    print_menu "Enter the format ID you want to download:"
    read -r format_id
    
    # Validate format ID
    if [[ -z "$format_id" ]]; then
        print_error "No format ID provided. Exiting."
        exit 1
    fi
    
    # Check if format ID exists for this video
    if ! yt-dlp --list-formats "$URL" 2>/dev/null | grep -q "^$format_id"; then
        print_error "Invalid format ID. Please check the available formats and try again."
        exit 1
    fi
    
    echo "$format_id"
}

# Main function
main() {
    print_step "YouTube Video/Audio Downloader with Format Selection"
    echo
    
    check_dependencies
    
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    # Get URL from user
    get_url
    
    # List available formats
    list_video_formats
    
    # Get format selection from user
    local format_id=$(get_format_selection)
    
    # Get output directory from user
    local output_dir=$(get_output_dir)
    
    # Download the selected format
    download_format "$format_id" "$output_dir"
}

# Run main function with all arguments
main "$@"
