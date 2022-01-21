## Configurable variables ##

PANDOC         := pandoc
CONTENT_DIR    := content
PUBLIC_DIR     := public
STYLES_DIR     := styles
FONTS_DIR      := fonts
HL_STYLE       := $(STYLES_DIR)/gruvbox-dark.theme
POST_TEMPLATE  := templates/post.html
INDEX_TEMPLATE := templates/index.html

# Font is a variable here but is not super easy to configure right now. You
# would need to change `styles/fonts.css` and the other style sheets. Only fonts
# available from 'Google Fonts' are supported for automatic download.
FONT           := Fira Code

## Automatic variables ##

STYLES         := $(wildcard $(STYLES_DIR)/*.css)
SOURCES        := $(shell find $(CONTENT_DIR) -name '*.md')
# The $(__NOTHING) was not defined, so it will be empty. We use this trick to
# write a literal space. Otherwise make would ignore the space.
ESCAPE_FONT    := $(subst $(__NOTHING) $(__NOTHING),_,$(strip $(FONT)))

# HTML
HTML_POSTS     := $(patsubst $(CONTENT_DIR)/posts/%.md, $(PUBLIC_DIR)/posts/%.html, $(SOURCES))
HTML_PAGES     := $(patsubst $(CONTENT_DIR)/%.md, $(PUBLIC_DIR)/%.html, $(SOURCES))

## Some utilities ##

# Colors
RESET   := \e[0m
BRED    := \e[1;31m
BGREEN  := \e[1;32m
BYELLOW := \e[1;33m
BBLUE   := \e[1;34m

fname = $(basename $(notdir $(1)))

## Rules ##

.PHONY: all clean cleanall pandoc html serve fonts
.PRECIOUS: ./ %/

all: $(HTML_PAGES)
html: $(HTML_PAGES)
echo_srcs:
	@echo $(SOURCES)

serve: html
	@printf "\t$(BYELLOW)SERVER$(RESET) http://localhost:8000\n"
	@cd public && python3 -m http.server

$(PUBLIC_DIR)/posts/%.html: $(CONTENT_DIR)/posts/%.md $(STYLES) $(POST_TEMPLATE) $(HL_STYLE) | $(PUBLIC_DIR)/posts/ pandoc fonts
	@printf "\t$(BBLUE)PANDOC$(RESET)\t$< -> $@\n"
	@$(PANDOC)                                                                                       \
		--from markdown+smart+escaped_line_breaks+header_attributes+line_blocks+fancy_lists+startnum \
		--to html                                                                                    \
		--self-contained                                                                             \
		--toc                                                                                        \
		--eol lf                                                                                     \
		--template $(POST_TEMPLATE)                                                                  \
		$(patsubst %, --css=%, $(STYLES))                                                            \
		--highlight-style $(HL_STYLE)                                                                \
		--output $@                                                                                  \
		$<

$(PUBLIC_DIR)/index.html: $(CONTENT_DIR)/index.md $(STYLES) $(INDEX_TEMPLATE) | $(PUBLIC_DIR)/ pandoc fonts
	@printf "\t$(BBLUE)PANDOC$(RESET)\t$< -> $@\n"
	@$(PANDOC)                                                                                       \
		--from markdown+smart+escaped_line_breaks+header_attributes+line_blocks+fancy_lists+startnum \
		--to html                                                                                    \
		--self-contained                                                                             \
		--eol lf                                                                                     \
		--template $(INDEX_TEMPLATE)                                                                 \
		$(patsubst %, --css=%, $(STYLES))                                                            \
		--output $@                                                                                  \
		$<

./:
%/:
	@printf "\t$(BGREEN)MKDIR$(RESET)\t$(patsubst %/,%,$@)\n"
	@mkdir -p $@

clean:
	@printf "\t$(BRED)RM$(RESET)\t$(PUBLIC_DIR)\n"
	@rm -rf $(PUBLIC_DIR)

cleanall: clean
	@printf "\t$(BRED)RM$(RESET)\t$(FONTS_DIR)\n"
	@rm -rf $(FONTS_DIR)

# If the font directory is not present, try to download it from Google Fonts.

ifeq ($(wildcard $(FONTS_DIR)/$(ESCAPE_FONT)/.),)
fonts: $(FONTS_DIR)/$(ESCAPE_FONT) | $(FONTS_DIR)/

FONT_URL := https://fonts.google.com/download?family=$(FONT)
$(FONTS_DIR)/$(ESCAPE_FONT): | $(FONTS_DIR)/
	@printf "\t$(BYELLOW)GET$(RESET)\t'Fira Code' @ $(FONT_URL)\n"
	@wget '$(FONT_URL)' -O $(ESCAPE_FONT).zip
	@unzip $(ESCAPE_FONT).zip -d $@
	@rm $(ESCAPE_FONT).zip
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
