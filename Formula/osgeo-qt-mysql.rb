class OsgeoQtMysql < Formula
  desc "Qt SQL Database Driver - QMYSQL for MySQL 4 and higher"
  homepage "https://doc.qt.io/qt-5/sql-driver.html"
  url "https://download.qt.io/official_releases/qt/5.12/5.12.2/single/qt-everywhere-src-5.12.2.tar.xz"
  sha256 "59b8cb4e728450b21224dcaaa40eb25bafc5196b6988f2225c394c6b7f881ff5"

  # revision 1

  head "https://code.qt.io/qt/qt5.git", :branch => "5.12", :shallow => false

  bottle do
    root_url "https://dl.bintray.com/homebrew-osgeo/osgeo-bottles"
    cellar :any
    rebuild 1
    sha256 "db16e512f400de27dc396fc2a1ef8301df74bcc3f7ca1399e663e0b9ef6f7b14" => :mojave
    sha256 "db16e512f400de27dc396fc2a1ef8301df74bcc3f7ca1399e663e0b9ef6f7b14" => :high_sierra
    sha256 "8a714204a79a434d375803422e1d8559cd1aeaab5cb952b1a9d70729b78e91a5" => :sierra
  end

  depends_on "pkg-config" => :build
  depends_on "libiconv"
  depends_on "gettext"
  depends_on "libxml2"
  depends_on "libxslt"
  depends_on "zlib"
  depends_on "qt"
  depends_on "sqlite"
  depends_on "openssl"
  depends_on "mysql"
  depends_on :xcode => :build

  def install
    qt_plugins = lib/"qt/plugins"
    (qt_plugins/"sqldrivers").mkpath

    chdir "#{buildpath}/qtbase/src/plugins/sqldrivers" do
      system "#{Formula["qt"].opt_bin}/qmake", "--", "MYSQL_PREFIX=#{Formula["mysql"].opt_prefix}"
      system "make"

      # copy libqsqlmysql.dylib
      # libqsqlite.dylib from qt
      cp_r "#{buildpath}/qtbase/src/plugins/sqldrivers/plugins/sqldrivers/libqsqlmysql.dylib", "#{lib}/qt/plugins/sqldrivers/"
    end
  end

  def caveats; <<~EOS
    Plugins generated are linked to the following directory:

      #{HOMEBREW_PREFIX}/lib/qt/plugins/sqldrivers
  EOS
  end

  test do
    (testpath/"hello.pro").write <<~EOS
      QT        += core sql
      QT        -= gui
      TARGET     = hello
      CONFIG    += console
      CONFIG    -= app_bundle
      TEMPLATE   = app
      HEADERS    = client.h
      SOURCES   += client.cpp main.cpp
    EOS

    (testpath/"client.h").write <<~EOS
    #ifndef CLIENT_H
    #define CLIENT_H
    #include <QObject>
    #include <QSqlDatabase>
    #include <QString>
    class Client : public QObject
    {
      Q_OBJECT
    public:
      Client(QObject *parent = 0);
    public slots:
      void checkSqlDriver();
    };
    #endif // CLIENT_H
    EOS

    (testpath/"client.cpp").write <<~EOS
    #include "client.h"
    #include <QCoreApplication>
    #include <QDebug>
    #include <QSqlDatabase>
    #include <QStringList>
    Client::Client(QObject *parent)
      : QObject(parent)
    {
    }
    void Client::checkSqlDriver()
    {
      QCoreApplication::addLibraryPath("#{HOMEBREW_PREFIX}/lib/qt/plugins");
      QCoreApplication::addLibraryPath("#{lib}/qt/plugins");
      qDebug() << "QSqlDatabase::drivers(): " << QSqlDatabase::drivers().join(" ");
      QCoreApplication::exit(!QSqlDatabase::isDriverAvailable("QMYSQL"));
    }
    EOS

    (testpath/"main.cpp").write <<~EOS
      #include <QCoreApplication>
      #include <QDebug>
      #include <QTimer>
      #include "client.h"
      int main(int argc, char *argv[])
      {
        QCoreApplication app(argc, argv);
        Client c(app.instance());
        qDebug() << "Running application";
        QTimer::singleShot(1000, &c, SLOT(checkSqlDriver()));
        return app.exec();
      }
    EOS

    cd testpath do
      system Formula["qt"].bin/"qmake", "hello.pro"
      system "make"
      assert_predicate testpath/"client.o", :exist?
      assert_predicate testpath/"moc_client.o", :exist?
      assert_predicate testpath/"main.o", :exist?
      assert_predicate testpath/"hello", :exist?
      system "./hello"
    end
  end
end
