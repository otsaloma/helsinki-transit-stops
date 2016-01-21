# Prevent brp-python-bytecompile from running.
%define __os_install_post %{___build_post}

# "Harbour RPM packages should not provide anything."
%define __provides_exclude_from ^%{_datadir}/.*$

Name: harbour-helsinki-transit-stops
Version: 1.4.1
Release: 1
Summary: Departures from HSL public transportation stops
License: GPLv3+
URL: http://github.com/otsaloma/helsinki-transit-stops
Source: %{name}-%{version}.tar.xz
BuildArch: noarch
BuildRequires: make
BuildRequires: qt5-qttools-linguist
Requires: libsailfishapp-launcher
Requires: pyotherside-qml-plugin-python3-qt5 >= 1.2
Requires: qt5-qtdeclarative-import-positioning >= 5.2
Requires: sailfishsilica-qt5

%description
View next buses, trams, trains, metro or ferries departing from a stop. View a
listing of nearby stops or search for stops by name. Mark frequently used stops
as favorites along with line filters.

Included are Helsinki Region Transport (HSL) public transportation stops.
Departures are from the Reittiopas API and based on schedules. Real-time
departures are not supported.

%prep
%setup -q

%install
make DESTDIR=%{buildroot} PREFIX=/usr install

%files
%defattr(-,root,root,-)
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
