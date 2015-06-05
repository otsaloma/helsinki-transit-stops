Translating Helsinki Transit Stops
==================================

Translate the file `helsinki-transit-stops.ts`. You can use for example
[Qt Linguist][1] or [Virtaal][2] or, if you know what you're doing, a
text editor. Save your file as `xx.ts` or `xx_YY.ts`, where `xx` is a
two-letter ISO 639 language code and `YY` is a two-letter ISO 3166
country code.

To try your translation, you can compile it and run qmlscene.

```sh
export PATH=$PATH:/usr/lib/qt5/bin
lrelease translations/xx.ts -qm translations/xx.qm
qmlscene -translation translations/xx.qm qml/helsinki-transit-stops.qml
```

To get your translation included, fork the [repository][3] on GitHub,
commit your changes and send a pull request, or if you prefer, send the
translation file by email to <otsaloma@iki.fi>.

[1]: http://doc.qt.io/qt-5/linguist-translators.html
[2]: http://virtaal.translatehouse.org/
[3]: http://github.com/otsaloma/helsinki-transit-stops
