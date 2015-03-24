# Prevent brp-python-bytecompile from running.
%define __os_install_post %{___build_post}

Name: harbour-helsinki-transit-stops
Version: 0.4
Release: 1
Summary: Departures from HSL public transportation stops
License: GPLv3+
URL: http://github.com/otsaloma/helsinki-transit-stops
Source: %{name}-%{version}.tar.xz
BuildArch: noarch
BuildRequires: make
Requires: libsailfishapp-launcher
Requires: pyotherside-qml-plugin-python3-qt5 >= 1.2
Requires: python3-base
Requires: qt5-qtdeclarative-import-positioning >= 5.2
Requires: sailfishsilica-qt5

%description
Departures from Helsinki Region Transport (HSL) public transportation stops.

%prep
%setup -q

%install
make DESTDIR=%{buildroot} PREFIX=/usr install

%files
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
