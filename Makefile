# -*- coding: us-ascii-unix -*-

NAME       = harbour-helsinki-transit-stops
VERSION    = 1.3
LANGS      = $(basename $(notdir $(wildcard po/*.po)))
POT_FILE   = po/helsinki-transit-stops.pot

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
	rm -f po/*.ts po/*~
	rm -f rpm/*.rpm

dist:
	$(MAKE) clean
	mkdir -p dist/$(NAME)-$(VERSION)
	cp -r `cat MANIFEST` dist/$(NAME)-$(VERSION)
	tar -C dist -cJf dist/$(NAME)-$(VERSION).tar.xz $(NAME)-$(VERSION)

define install-translations =
# GNU gettext translations for Python use.
mkdir -p $(DATADIR)/locale/$(1)/LC_MESSAGES
msgfmt po/$(1).po -o $(DATADIR)/locale/$(1)/LC_MESSAGES/hts.mo
# Qt linguist translations for QML use.
mkdir -p $(DATADIR)/translations
lconvert -o $(DATADIR)/translations/$(NAME)-$(1).qm po/$(1).po
endef

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
	$(foreach lang,$(LANGS),$(call install-translations,$(lang)))
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

translations:
	truncate -s0 $(POT_FILE)
	xgettext \
	 --output=$(POT_FILE) \
	 --language=Python \
	 --from-code=UTF-8 \
	 --join-existing \
	 --keyword=gt \
	 hts/*.py
	xgettext \
	 --output=$(POT_FILE) \
	 --language=JavaScript \
	 --from-code=UTF-8 \
	 --join-existing \
	 --keyword=qsTr \
	 qml/*.qml
	cd po && for X in *.po; do msgmerge -UN $$X *.pot; done

.PHONY: check clean dist install rpm test translations
