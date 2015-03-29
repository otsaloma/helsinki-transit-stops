# -*- coding: us-ascii-unix -*-

name       = harbour-helsinki-transit-stops
version    = 0.4.1
DESTDIR    =
PREFIX     = /usr
datadir    = $(DESTDIR)$(PREFIX)/share/$(name)
desktopdir = $(DESTDIR)$(PREFIX)/share/applications
icondir    = $(DESTDIR)$(PREFIX)/share/icons/hicolor/86x86/apps

.PHONY: clean dist install rpm translations

clean:
	rm -rf dist
	rm -rf __pycache__ */__pycache__ */*/__pycache__
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
	mkdir -p $(datadir)/qml/icons
	cp qml/helsinki-transit-stops.qml $(datadir)/qml/$(name).qml
	cp qml/[ABCDEFGHIJKLMNOPQRSTUVXYZ]*.qml $(datadir)/qml
	cp qml/icons/*.png $(datadir)/qml/icons
	@echo "Installing translations..."
	mkdir -p $(datadir)/translations
	for TSFILE in translations/??[!l]*ts; do \
	    LANG=`basename $$TSFILE .ts`; \
	    lrelease translations/$$LANG.ts \
	        -qm $(datadir)/translations/$(name)-$$LANG.qm; \
	done
	@echo "Installing desktop file..."
	mkdir -p $(desktopdir)
	cp data/$(name).desktop $(desktopdir)
	@echo "Installing icon..."
	mkdir -p $(icondir)
	cp data/helsinki-transit-stops.png $(icondir)/$(name).png

rpm:
	mkdir -p $$HOME/rpmbuild/SOURCES
	cp dist/$(name)-$(version).tar.xz $$HOME/rpmbuild/SOURCES
	rm -rf $$HOME/rpmbuild/BUILD*/$(name)-$(version)*
	rpmbuild -ba rpm/$(name).spec
	cp $$HOME/rpmbuild/RPMS/noarch/$(name)-$(version)-*.rpm rpm
	cp $$HOME/rpmbuild/SRPMS/$(name)-$(version)-*.rpm rpm

translations:
	rm -f translations/helsinki-transit-stops.ts
	lupdate qml/*.qml -ts qml.ts
	pylupdate5 -verbose hts/*.py -ts py.ts
	lconvert -o translations/helsinki-transit-stops.ts qml.ts py.ts
	rm -f qml.ts py.ts
	for TSFILE in translations/??[!l]*ts; do \
	    LANG=`basename $$TSFILE .ts`; \
	    lconvert --source-language en_US \
	             --target-language $$LANG \
	             -o translations/$$LANG.ts \
	             translations/helsinki-transit-stops.ts \
	             translations/$$LANG.ts; \
	done
