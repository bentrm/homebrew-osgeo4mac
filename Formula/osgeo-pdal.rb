class OsgeoPdal < Formula
  include Language::Python::Virtualenv
  desc "Point data abstraction library"
  homepage "https://www.pdal.io/"
  url "https://github.com/PDAL/PDAL/archive/1.8.0.tar.gz"
  sha256 "ef3a32c06865383feac46fd7eb7491f034cad6b0b246b3c917271ae0c8f25b69"

  bottle do
    root_url "https://dl.bintray.com/homebrew-osgeo/osgeo-bottles"
    sha256 "f4c18fb9fcaae698f44998b92035d1119efe129de66744148e6c92dcadcce848" => :mojave
    sha256 "f4c18fb9fcaae698f44998b92035d1119efe129de66744148e6c92dcadcce848" => :high_sierra
    sha256 "641d47c8a0b5bc66251ef076c75cfa20fa3e97c49e3887005ad1a484cea6ff01" => :sierra
  end

  # revision 1

  head "https://github.com/PDAL/PDAL.git", :branch => "master"

  option "with-postgresql10", "Build with PostgreSQL 10 client"

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "python"
  depends_on "numpy"
  depends_on "hdf5"
  depends_on "libgeotiff"
  depends_on "jsoncpp"
  depends_on "sqlite"
  depends_on "osgeo-gdal"
  depends_on "osgeo-laz-perf"
  depends_on "osgeo-vtk"
  depends_on "osgeo-pcl"
  depends_on "osgeo-hexer"
  depends_on "laszip" # >= 3.1
  depends_on "geos"
  depends_on "zlib"
  depends_on "libxml2"
  depends_on "curl"
  depends_on "boost"
  depends_on "qt"
  depends_on "eigen"
  depends_on "flann"
  depends_on "libusb"
  depends_on "qhull"
  depends_on "glew"

  if build.with?("postgresql10")
    depends_on "postgresql@10"
  else
    depends_on "postgresql"
  end

  # -- The following features have been disabled:
  #  * Bash completion, completion for PDAL command line
  #  * CPD plugin, Coherent Point Drift (CPD) computes rigid or nonrigid transformations between point sets
  #  * Delaunay plugin, perform Delaunay triangulation of point cloud
  #  * GeoWave plugin, Read and Write data using GeoWave
  #  * I3S plugin, Read from a I3S server or from a SLPK file
  #  * Matlab plugin, write data to a .mat file
  #  * MrSID plugin, read data in the MrSID format
  #  * NITF plugin, read/write LAS data wrapped in NITF
  #  * OpenSceneGraph plugin, read/write OpenSceneGraph objects
  #  * Oracle OCI plugin, Read/write point clould patches to Oracle
  #  * RiVLib plugin, read data in the RXP format
  #  * rdblib plugin, read data in the RDB format
  #  * MBIO plugin, add features that depend on MBIO
  #  * FBX plugin, add features that depend on FBX

  def install
    ENV.cxx11

    args = std_cmake_args

    args += %W[
      -DBUILD_PLUGIN_GREYHOUND=ON
      -DBUILD_PLUGIN_ICEBRIDGE=ON
      -DBUILD_PLUGIN_PCL=ON
      -DBUILD_PLUGIN_PGPOINTCLOUD=ON
      -DBUILD_PLUGIN_PYTHON=ON
      -DBUILD_PLUGIN_SQLITE=ON
      -DWITH_LASZIP=TRUE
      -DWITH_LAZPERF=ON"
    ]

    # args << "-DBUILD_PLUGIN_HEXBIN=ON" # not used by the project

    args << "-DLASZIP_LIBRARIES=#{Formula["laszip"].opt_lib}/liblaszip.dylib"
    args << "-DLASZIP_INCLUDE_DIR=#{Formula["laszip"].opt_include}"

    args << "-DPYTHON_EXECUTABLE=#{Formula["python"].opt_bin}/python#{py_ver}"
    args << "-DPYTHON_INCLUDE_DIR=#{Formula["python"].opt_frameworks}/Python.framework/Versions/#{py_ver}/Headers"
    args << "-DPYTHON_LIBRARY=#{Formula["python"].opt_frameworks}/Python.framework/Versions/#{py_ver}/lib/libpython#{py_ver}.dylib"

    if build.with?("postgresql10")
      args << "-DPG_CONFIG=#{Formula["postgresql@10"].opt_bin}/pg_config"
      args << "-DPOSTGRESQL_INCLUDE_DIR=#{Formula["postgresql@10"].opt_include}"
      args << "-DPOSTGRESQL_LIBRARIES=#{Formula["postgresql@10"].opt_lib}/libpq.dylib"
    else
      args << "-DPG_CONFIG=#{Formula["postgresql"].opt_bin}/pg_config"
      args << "-DPOSTGRESQL_INCLUDE_DIR=#{Formula["postgresql"].opt_include}"
      args << "-DPOSTGRESQL_LIBRARIES=#{Formula["postgresql"].opt_lib}/libpq.dylib"
    end

    system "cmake", ".", *args
    system "make", "install"
    doc.install "examples", "test"
  end

  test do
    system bin/"pdal", "info", doc/"test/data/las/interesting.las"
  end

  private

  def py_ver
    `#{Formula["python"].opt_bin}/python3 -c 'import sys;print("{0}.{1}".format(sys.version_info[0],sys.version_info[1]))'`.strip
  end
end
