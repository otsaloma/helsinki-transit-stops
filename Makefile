# -*- coding: us-ascii-unix -*-

NAME       = harbour-helsinki-transit-stops
VERSION    = 1.3
LANGS      = $(basename $(notdir $(filter-out \
    translations/helsinki-transit-stops.ts,\
    $(wildcard translations/*.ts))))

DESTDIR    =
PREFIX     = /usr
DATADIR    = $(DESTDIR)$(PREFIX)/share/$(NAME)
DESKTOPDIR = $(DESTDIR)$(PREFIX)/share/applications
ICONDIR    = $(DESTDIR)$(PREFIX)/share/icons/hicolor

export PATH := $(PATH):/usr/lib/qt5/bin

check:
	pyflakes hts

clean:
	rm -rf dist
	rm -rf .cache */.cache */*/.cache
	rm -rf __pycache__ */__pycache__ */*/__pycache__
	rm -f rpm/*.rpm
	rm -f translations/*.qm

dist:
	$(MAKE) clean
	mkdir -p dist/$(NAME)-$(VERSION)
	cp -r `cat MANIFEST` dist/$(NAME)-$(VERSION)
	tar -C dist -cJf dist/$(NAME)-$(VERSION).tar.xz $(NAME)-$(VERSION)

install:
	@echo "Installing Python files..."
	mkdir -p $(DATADIR)/hts
	cp hts/*.py $(DATADIR)/hts
	@echo "Installing QML files..."
	mkdir -p $(DATADIR)/qml/icons
	cp qml/helsinki-transit-stops.qml $(DATADIR)/qml/$(NAME).qml
	cp qml/[ABCDEFGHIJKLMNOPQRSTUVXYZ]*.qml $(DATADIR)/qml
	cp qml/icons/*.png $(DATADIR)/qml/icons
	@echo "Installing translations..."
	mkdir -p $(DATADIR)/translations
	$(foreach lang,$(LANGS),lrelease translations/$(lang).ts \
	    -qm $(DATADIR)/translations/$(NAME)-$(lang).qm;)
	@echo "Installing desktop file..."
	mkdir -p $(DESKTOPDIR)
	cp data/$(NAME).desktop $(DESKTOPDIR)
	@echo "Installing icons..."
	mkdir -p $(ICONDIR)/86x86/apps
	mkdir -p $(ICONDIR)/108x108/apps
	mkdir -p $(ICONDIR)/128x128/apps
	mkdir -p $(ICONDIR)/256x256/apps
	cp data/helsinki-transit-stops-86.png  $(ICONDIR)/86x86/apps/$(NAME).png
	cp data/helsinki-transit-stops-108.png $(ICONDIR)/108x108/apps/$(NAME).png
	cp data/helsinki-transit-stops-128.png $(ICONDIR)/128x128/apps/$(NAME).png
	cp data/helsinki-transit-stops-256.png $(ICONDIR)/256x256/apps/$(NAME).png

rpm:
	$(MAKE) dist
	mkdir -p $$HOME/rpmbuild/SOURCES
	cp dist/$(NAME)-$(VERSION).tar.xz $$HOME/rpmbuild/SOURCES
	rm -rf $$HOME/rpmbuild/BUILD*/$(NAME)-$(VERSION)*
	rpmbuild -ba --nodeps rpm/$(NAME).spec
	cp $$HOME/rpmbuild/RPMS/noarch/$(NAME)-$(VERSION)-*.rpm rpm
	cp $$HOME/rpmbuild/SRPMS/$(NAME)-$(VERSION)-*.rpm rpm

test:
	py.test hts

define merge-translations =
lconvert \
    --source-language en \
    --target-language $(1) \
    --no-obsolete \
    -o translations/$(1).ts \
    $(2) translations/$(1).ts
endef

translations:
	lupdate qml/*.qml -ts qml.ts
	pylupdate5 -verbose hts/*.py -ts py.ts
	lupdate -pluralonly qml/*.qml -ts plural.ts
	rm -f translations/helsinki-transit-stops.ts
	lconvert -o translations/helsinki-transit-stops.ts qml.ts py.ts
	$(call merge-translations,en,plural.ts)
	$(foreach lang,$(filter-out en,$(LANGS)),$(call \
	    merge-translations,$(lang),translations/helsinki-transit-stops.ts))
	rm -f qml.ts py.ts plural.ts

.PHONY: check clean dist install rpm test translations
