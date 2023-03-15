## Configurable variables ##

PANDOC         := pandoc
CONTENT_DIR    := content
PUBLIC_DIR     := public
PDF_DIR        := pdf
STYLES_DIR     := styles
TEMPLATE_DIR   := templates
FONTS_DIR      := fonts
BUILD_DIR      := build
HTML_HL_STYLE  := $(STYLES_DIR)/gruvbox-dark.theme
PDF_HL_STYLE   := $(STYLES_DIR)/gruvbox-light.theme
PDF_TEMPLATE   := $(TEMPLATE_DIR)/pdf.latex
POST_TEMPLATE  := $(TEMPLATE_DIR)/post.html
INDEX_TEMPLATE := $(TEMPLATE_DIR)/index.html
CARD_TEMPLATE  := $(TEMPLATE_DIR)/card.html
AUX_TEMPLATE   := $(TEMPLATE_DIR)/header.html
MARKDOWN       := markdown

# Font is a variable here but is not super easy to configure right now. You
# would need to change `styles/fonts.css` and the other style sheets. Only fonts
# available from 'Google Fonts' are supported for automatic download.
FONT           := Fira Code

## Automatic variables ##

STYLES         := $(wildcard $(STYLES_DIR)/*.css)
SOURCES        := $(shell find $(CONTENT_DIR) -name '*.md')
POSTS          := $(wildcard $(CONTENT_DIR)/posts/*.md)
# The $(__NOTHING) was not defined, so it will be empty. We use this trick to
# write a literal space. Otherwise make would ignore the space.
ESC_FONT       := $(subst $(__NOTHING) $(__NOTHING),_,$(strip $(FONT)))

# HTML
HTML_POSTS     := $(patsubst $(CONTENT_DIR)/%.md, $(PUBLIC_DIR)/%.html, $(POSTS))
HTML_PAGES     := $(HTML_POSTS) $(PUBLIC_DIR)/index.html
HTML_CARDS     := $(patsubst %.md,$(BUILD_DIR)/%-card.html,$(notdir $(POSTS)))

# PDF
PDF_POSTS     := $(patsubst $(CONTENT_DIR)/posts/%.md, $(PDF_DIR)/%.pdf, $(POSTS))

## Some utilities ##

# Colors
RESET   := \e[0m
BRED    := \e[1;31m
BGREEN  := \e[1;32m
BYELLOW := \e[1;33m
BBLUE   := \e[1;34m

fname = $(basename $(notdir $(1)))

## Rules ##

.PHONY: all clean cleanall pandoc html serve fonts copy_styles pdf
.PRECIOUS: ./ %/

all: $(HTML_PAGES) | copy_styles
html: $(HTML_PAGES)
pdf: $(PDF_POSTS)

copy_styles: $(patsubst $(STYLES_DIR)/%.css,$(PUBLIC_DIR)/styles/%.css,$(STYLES))

$(PUBLIC_DIR)/styles/%.css: $(STYLES_DIR)/%.css | $(PUBLIC_DIR)/styles/
	@printf "\t$(BGREEN)CP$(RESET)\t$^ -> public/styles\n"
	@cp $^ $(PUBLIC_DIR)/styles

serve: html
	@printf "\t$(BYELLOW)SERVER$(RESET) http://localhost:8000\n"
	@cd public && python3 -m http.server

$(PDF_DIR)/%.pdf: $(CONTENT_DIR)/posts/%.md $(PDF_HL_STYLE) | $(PDF_DIR)/ pandoc
	@printf "\t$(BBLUE)PANDOC$(RESET)\t$< -> $@\n"
	@$(PANDOC)                            \
		--from $(MARKDOWN)                \
		--to pdf                          \
		--standalone                      \
		--toc                             \
		--eol lf                          \
		--pdf-engine=xelatex              \
		--wrap none                       \
		--highlight-style $(PDF_HL_STYLE) \
		 -V geometry:margin=1in           \
		--output $@                       \
		$<

# Prettier, but --embed-resources is broken
# $(PUBLIC_DIR)/posts/%.html: $(CONTENT_DIR)/posts/%.md $(STYLES) $(POST_TEMPLATE) $(INDEX_AUX) $(HTML_HL_STYLE) | $(PUBLIC_DIR)/posts/ pandoc fonts
# 	@printf "\t$(BBLUE)PANDOC$(RESET)\t$< -> $@\n"
# 	@$(PANDOC)                            \
# 		--from $(MARKDOWN)                \
# 		--to html                         \
# 		--standalone                      \
# 		--toc                             \
# 		--eol lf                          \
# 		--katex=https://cdn.jsdelivr.net/npm/katex@0.16.4/dist/                           \
# 		--wrap none                       \
# 		--template $(POST_TEMPLATE)       \
# 		$(patsubst %, --css=/%, $(STYLES)) \
# 		--highlight-style $(HTML_HL_STYLE)     \
# 		--output $@                       \
# 		$<

$(PUBLIC_DIR)/posts/%.html: $(CONTENT_DIR)/posts/%.md $(STYLES) $(POST_TEMPLATE) $(INDEX_AUX) $(HTML_HL_STYLE) | $(PUBLIC_DIR)/posts/ pandoc fonts
	@printf "\t$(BBLUE)PANDOC$(RESET)\t$< -> $@\n"
	@$(PANDOC)                                        \
		--from $(MARKDOWN)                            \
		--to html                                     \
		--standalone                                  \
		--embed-resources                             \
		--toc                                         \
		--eol lf                                      \
		--mathjax                                     \
		--wrap none                                   \
		--template $(POST_TEMPLATE)                   \
		$(patsubst %, --css=%, $(STYLES))             \
		--highlight-style $(HTML_HL_STYLE)            \
		--output $@                                   \
		$<

$(PUBLIC_DIR)/index.html: $(CONTENT_DIR)/index.md $(STYLES) $(HTML_CARDS) $(INDEX_TEMPLATE) $(INDEX_AUX) | $(PUBLIC_DIR)/ pandoc fonts
	@printf "\t$(BBLUE)PANDOC$(RESET)\t$@\n"
	@$(PANDOC)                                                 \
		--from $(MARKDOWN)                                     \
		--to html                                              \
		--standalone                                           \
		--eol lf                                               \
		--katex=https://cdn.jsdelivr.net/npm/katex@0.16.4/dist/                           \
		--wrap none                                            \
		--template $(INDEX_TEMPLATE)                           \
		$(patsubst %, --css="%", $(STYLES))                    \
		$(patsubst %, --include-after-body="%", $(HTML_CARDS)) \
		--output $@                                            \
		$<

$(BUILD_DIR)/%-card.html: $(CONTENT_DIR)/posts/%.md $(CARD_TEMPLATE) | build/
	@printf "\t$(BBLUE)PANDOC$(RESET)\t$< -> $@\n"
	@$(PANDOC)                          \
		--from $(MARKDOWN)              \
		--to html                       \
		--eol lf                        \
		--wrap none                     \
		--template $(CARD_TEMPLATE)     \
		--variable="link:posts/$*.html" \
		--output $@                     \
		$<

./:
%/:
	@printf "\t$(BGREEN)MKDIR$(RESET)\t$(patsubst %/,%,$@)\n"
	@mkdir -p $@

clean:
	@printf "\t$(BRED)RM$(RESET)\t$(PUBLIC_DIR)\n"
	@rm -rf $(PUBLIC_DIR)
	@printf "\t$(BRED)RM$(RESET)\t$(BUILD_DIR)\n"
	@rm -rf $(BUILD_DIR)

cleanall: clean
	@printf "\t$(BRED)RM$(RESET)\t$(FONTS_DIR)\n"
	@rm -rf $(FONTS_DIR)

# If the font directory is not present, try to download it from Google Fonts.

ifeq ($(wildcard $(FONTS_DIR)/$(ESC_FONT)/.),)
fonts: $(FONTS_DIR)/$(ESC_FONT) | $(FONTS_DIR)/

FONT_URL := https://fonts.google.com/download?family=$(FONT)
$(FONTS_DIR)/$(ESC_FONT): | $(FONTS_DIR)/
	@printf "\t$(BYELLOW)GET$(RESET)\t'Fira Code' @ $(FONT_URL)\n"
	@wget '$(FONT_URL)' -O $(ESC_FONT).zip
	@unzip $(ESC_FONT).zip -d $@
	@rm $(ESC_FONT).zip
else
fonts:
endif

# If `$(PANDOC)` is defined to be the command `pandoc`. Then we want to check if
# it is available. However, if it is anything else (like a docker command), just
# do nothing.

ifeq ($(PANDOC),pandoc)
pandoc:
	@if ! command -v pandoc 2>&1 > /dev/null; then   \
		echo "Couldn't find pandoc, installing now"; \
		sudo apt install -y pandoc;                  \
	fi
else
pandoc:
endif
