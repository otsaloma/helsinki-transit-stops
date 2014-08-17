# -*- coding: us-ascii-unix -*-

name       = harbour-helsinki-transit-stops
version    = 0.0
DESTDIR    =
PREFIX     = /usr/local
datadir    = $(DESTDIR)$(PREFIX)/share/$(name)
desktopdir = $(DESTDIR)$(PREFIX)/share/applications
icondir    = $(DESTDIR)$(PREFIX)/share/icons/hicolor/86x86/apps

.PHONY: clean dist install rpm

clean:
	rm -rf dist hts/__pycache__
	rm -f rpm/*.rpm

dist:
	$(MAKE) clean
	mkdir -p dist/$(name)-$(version)
	cp -r `cat MANIFEST` dist/$(name)-$(version)
	tar -C dist -cJf dist/$(name)-$(version).tar.xz $(name)-$(version)

install:
	@echo "Installing Python files..."
	mkdir -p $(datadir)/hts
	cp hts/*.py $(datadir)/hts
	@echo "Installing QML files..."
	mkdir -p $(datadir)/qml
	cp qml/helsinki-transit-stops.qml $(datadir)/qml/$(name).qml
	cp qml/[ABCDEFGHIJKLMNOPQRSTUVXYZ]*.qml $(datadir)/qml
	@echo "Installing desktop file..."
	mkdir -p $(desktopdir)
	cp data/$(name).desktop $(desktopdir)
	@echo "Installing icon..."
	mkdir -p $(icondir)
	cp data/helsinki-transit-stops.png $(icondir)/$(name).png

rpm:
	mkdir -p $$HOME/rpmbuild/SOURCES
	cp dist/$(name)-$(version).tar.xz $$HOME/rpmbuild/SOURCES
	rpmbuild -ba rpm/$(name).spec
	cp $$HOME/rpmbuild/RPMS/noarch/$(name)-$(version)-*.rpm rpm
	cp $$HOME/rpmbuild/SRPMS/$(name)-$(version)-*.rpm rpm
