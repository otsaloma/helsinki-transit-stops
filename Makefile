# -*- coding: us-ascii-unix -*-

NAME       = harbour-helsinki-transit-stops
VERSION    = 1.0.1

DESTDIR    =
PREFIX     = /usr
DATADIR    = $(DESTDIR)$(PREFIX)/share/$(NAME)
DESKTOPDIR = $(DESTDIR)$(PREFIX)/share/applications
ICONDIR    = $(DESTDIR)$(PREFIX)/share/icons/hicolor/86x86/apps

export PATH := $(PATH):/usr/lib/qt5/bin

clean:
	rm -rf dist
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
	for TSFILE in translations/??[!l]*ts; do \
	    LANG=`basename $$TSFILE .ts`; \
	    lrelease translations/$$LANG.ts \
	        -qm $(DATADIR)/translations/$(NAME)-$$LANG.qm; \
	done
	@echo "Installing desktop file..."
	mkdir -p $(DESKTOPDIR)
	cp data/$(NAME).desktop $(DESKTOPDIR)
	@echo "Installing icon..."
	mkdir -p $(ICONDIR)
	cp data/helsinki-transit-stops.png $(ICONDIR)/$(NAME).png

rpm:
	mkdir -p $$HOME/rpmbuild/SOURCES
	cp dist/$(NAME)-$(VERSION).tar.xz $$HOME/rpmbuild/SOURCES
	rm -rf $$HOME/rpmbuild/BUILD*/$(NAME)-$(VERSION)*
	rpmbuild -ba rpm/$(NAME).spec
	cp $$HOME/rpmbuild/RPMS/noarch/$(NAME)-$(VERSION)-*.rpm rpm
	cp $$HOME/rpmbuild/SRPMS/$(NAME)-$(VERSION)-*.rpm rpm

translations:
	lupdate qml/*.qml -ts qml.ts
	pylupdate5 -verbose hts/*.py -ts py.ts
	lupdate -pluralonly qml/*.qml -ts plural.ts
	rm -f translations/helsinki-transit-stops.ts
	lconvert -o translations/helsinki-transit-stops.ts qml.ts py.ts
	for TSFILE in translations/??[!l]*ts; do \
	    LANG=`basename $$TSFILE .ts`; \
	    TSSOURCE=translations/helsinki-transit-stops.ts; \
	    [ $$LANG = en ] && TSSOURCE=plural.ts; \
	    lconvert --source-language en \
	             --target-language $$LANG \
	             -o translations/$$LANG.ts \
	             $$TSSOURCE \
	             translations/$$LANG.ts; \
	done
	rm -f qml.ts py.ts plural.ts

.PHONY: clean dist install rpm translations
