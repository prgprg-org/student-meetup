# Makefile for Student PL Meetup Poster
# Automates Typst compilation with local fonts

# Variables
TYPST = typst
MAIN_FILE = main.typ
FONT_PATH = fonts
OUTPUT_DIR = output
FINAL_PDF = invite.pdf
WATCH_PDF = invite-watch.pdf

# Default target - compile with local fonts
.PHONY: all
all: $(FINAL_PDF)

# Compile with exact website fonts (recommended)
$(FINAL_PDF): $(MAIN_FILE)
	@echo "🎨 Compiling poster with exact website fonts..."
	$(TYPST) compile --font-path $(FONT_PATH) $(MAIN_FILE) $(FINAL_PDF)
	@echo "✅ Poster compiled: $(FINAL_PDF)"

# Quick compilation with fallback fonts (faster, no font-path needed)
.PHONY: quick
quick:
	@echo "⚡ Quick compilation with fallback fonts..."
	$(TYPST) compile $(MAIN_FILE) invite-quick.pdf
	@echo "✅ Quick build: invite-quick.pdf"

# Watch mode for development (auto-recompile on changes)
.PHONY: watch
watch:
	@echo "👀 Starting watch mode with website fonts..."
	@echo "📝 Edit $(MAIN_FILE) and see changes automatically!"
	@echo "🛑 Press Ctrl+C to stop"
	$(TYPST) watch --font-path $(FONT_PATH) $(MAIN_FILE) $(WATCH_PDF)

# Watch mode with fallback fonts (faster)
.PHONY: watch-quick
watch-quick:
	@echo "👀 Starting quick watch mode with fallback fonts..."
	@echo "📝 Edit $(MAIN_FILE) and see changes automatically!"
	@echo "🛑 Press Ctrl+C to stop"
	$(TYPST) watch $(MAIN_FILE) invite-watch-quick.pdf

# Create organized output directory and compile multiple versions
.PHONY: release
release:
	@echo "📦 Creating release builds..."
	@mkdir -p $(OUTPUT_DIR)
	$(TYPST) compile --font-path $(FONT_PATH) $(MAIN_FILE) $(OUTPUT_DIR)/invite-final.pdf
	$(TYPST) compile $(MAIN_FILE) $(OUTPUT_DIR)/invite-fallback.pdf
	@echo "✅ Release builds created in $(OUTPUT_DIR)/"
	@echo "   📄 invite-final.pdf (with website fonts)"
	@echo "   📄 invite-fallback.pdf (with system fonts)"

# Check if fonts are available
.PHONY: check-fonts
check-fonts:
	@echo "🔍 Checking local fonts..."
	@if [ -d "$(FONT_PATH)" ]; then \
		echo "✅ Font directory exists: $(FONT_PATH)/"; \
		echo "📁 Available fonts:"; \
		ls -la $(FONT_PATH)/*.ttf 2>/dev/null || echo "❌ No .ttf files found"; \
	else \
		echo "❌ Font directory missing: $(FONT_PATH)/"; \
		echo "💡 Run 'make download-fonts' to get website fonts"; \
	fi

# Download website fonts (if needed)
.PHONY: download-fonts
download-fonts:
	@echo "⬇️  Downloading website fonts..."
	@mkdir -p $(FONT_PATH)
	@cd $(FONT_PATH) && \
	wget -q "https://fonts.googleapis.com/css2?family=Neuton:wght@200;300;400;700;800&display=swap" -O neuton.css && \
	wget -q "https://fonts.googleapis.com/css2?family=Manrope:wght@200;300;400;500;600;700;800&display=swap" -O manrope.css && \
	wget -q "https://fonts.gstatic.com/s/neuton/v24/UMBTrPtMoH62xUZyyA.ttf" -O Neuton-Regular.ttf && \
	wget -q "https://fonts.gstatic.com/s/neuton/v24/UMBQrPtMoH62xUZKdK0feg.ttf" -O Neuton-Bold.ttf && \
	wget -q "https://fonts.gstatic.com/s/manrope/v20/xn7_YHE41ni1AdIRqAuZuw1Bx9mbZk79FO_F.ttf" -O Manrope-Regular.ttf && \
	wget -q "https://fonts.gstatic.com/s/manrope/v20/xn7_YHE41ni1AdIRqAuZuw1Bx9mbZk4jE-_F.ttf" -O Manrope-SemiBold.ttf && \
	wget -q "https://fonts.gstatic.com/s/manrope/v20/xn7_YHE41ni1AdIRqAuZuw1Bx9mbZk4aE-_F.ttf" -O Manrope-Bold.ttf && \
	rm -f *.css
	@echo "✅ Website fonts downloaded to $(FONT_PATH)/"

# Clean generated files
.PHONY: clean
clean:
	@echo "🧹 Cleaning generated files..."
	@rm -f *.pdf
	@rm -rf $(OUTPUT_DIR)
	@echo "✅ Cleaned PDF files and output directory"

# Clean everything including fonts
.PHONY: clean-all
clean-all: clean
	@echo "🧹 Cleaning fonts..."
	@rm -rf $(FONT_PATH)
	@echo "✅ Cleaned everything"

# Show available targets
.PHONY: help
help:
	@echo "📋 Available Makefile targets:"
	@echo ""
	@echo "🎯 Main targets:"
	@echo "  make          - Compile poster with website fonts (default)"
	@echo "  make quick    - Quick compile with fallback fonts"
	@echo "  make watch    - Watch mode with website fonts"
	@echo "  make release  - Create release builds"
	@echo ""
	@echo "🔧 Utility targets:"
	@echo "  make check-fonts     - Check if fonts are available"
	@echo "  make download-fonts  - Download website fonts"
	@echo "  make clean          - Remove generated PDF files"
	@echo "  make clean-all      - Remove PDFs and fonts"
	@echo "  make help           - Show this help"
	@echo ""
	@echo "💡 Examples:"
	@echo "  make                 # Compile invite.pdf with website fonts"
	@echo "  make watch           # Auto-recompile on file changes"
	@echo "  make release         # Create final release versions"

# Verify Typst is installed
.PHONY: check-typst
check-typst:
	@echo "🔍 Checking Typst installation..."
	@which $(TYPST) > /dev/null || (echo "❌ Typst not found. Install from https://typst.app/" && exit 1)
	@echo "✅ Typst found: $$($(TYPST) --version)"

# Show project status
.PHONY: status
status: check-typst check-fonts
	@echo ""
	@echo "📊 Project Status:"
	@echo "  📄 Main file: $(MAIN_FILE)"
	@echo "  🎨 Font path: $(FONT_PATH)/"
	@echo "  📁 Output: $(FINAL_PDF)"
	@echo ""
	@echo "🚀 Ready to compile!"
