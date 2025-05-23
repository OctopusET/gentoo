# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )
JAVA_PKG_WANT_SOURCE="11"
JAVA_PKG_WANT_TARGET="11"

WEBAPP_MANUAL_SLOT=yes
WEBAPP_OPTIONAL=yes

inherit cmake depend.apache java-pkg-opt-2 perl-functions python-r1 webapp

DESCRIPTION="Development environment for building spatially enabled webapps"
HOMEPAGE="https://mapserver.org/"
SRC_URI="https://download.osgeo.org/mapserver/${P}.tar.gz"

LICENSE="Boost-1.0 BSD BSD-2 ISC MIT tcltk"
SLOT="0"
KEYWORDS="~amd64 ~x86"
# NOTE: opengl removed for now as no support for it in upstream CMake
IUSE="apache bidi cairo geos java mysql oracle perl postgis python test"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"
RESTRICT="!test? ( test )"

RDEPEND="
	>=dev-libs/expat-2.2.8
	dev-libs/libxml2:2=
	dev-libs/libxslt[crypt]
	>=dev-libs/protobuf-c-1.3.2:=
	>=media-libs/freetype-2.9.1-r3
	>=media-libs/gd-2.0.12:=[truetype,jpeg,png,zlib]
	>=media-libs/giflib-5.2.1:=
	media-libs/libjpeg-turbo
	>=media-libs/libpng-1.6.37:=
	>=net-misc/curl-7.69.1
	>=sci-libs/gdal-3.0.4:=[oracle?]
	>=sci-libs/proj-6.2.1:=
	virtual/libiconv
	>=x11-libs/agg-2.5-r3
	apache? (
		app-admin/webapp-config
		dev-libs/fcgi
	)
	bidi? (
		dev-libs/fribidi
		media-libs/harfbuzz:=
	)
	cairo? ( x11-libs/cairo )
	geos? ( sci-libs/geos )
	mysql? ( dev-db/mysql-connector-c:= )
	oracle? ( dev-db/oracle-instantclient:=	)
	perl? ( dev-lang/perl:= )
	postgis? (
		dev-db/postgis
		dev-db/postgresql:=
	)
	python? ( ${PYTHON_DEPS} )
"
DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
	java? (
		virtual/jdk
		>=dev-lang/swig-4.0
	)
	perl? ( >=dev-lang/swig-4.0 )
	python? (
		>=dev-lang/swig-4.0
		>=dev-python/setuptools-44.1.0
	)
"

want_apache2 apache

pkg_setup() {
	use apache && webapp_pkg_setup
	use perl && perl_set_version

	if use java ; then
		QA_SONAME="usr/$(get_libdir)/libjavamapscript.so"
	fi
}

src_prepare() {
	cmake_src_prepare

	use python && python_copy_sources
}

_generate_cmake_args() {
	# Provides a simple, bare config for bindings to build upon
	# Need WITH_WMS=ON or build fails
	local args=(
		"-DCMAKE_SKIP_RPATH=ON"
		"-DINSTALL_LIB_DIR=/usr/$(get_libdir)"
		"-DCMAKE_INSTALL_SYSCONFDIR=/usr/share/${PN}"
		"-DWITH_CAIRO=OFF"
		"-DWITH_FCGI=OFF"
		"-DWITH_FRIBIDI=OFF"
		"-DWITH_GEOS=OFF"
		"-DWITH_GIF=OFF"
		"-DWITH_HARFBUZZ=OFF"
		"-DWITH_ICONV=OFF"
		"-DWITH_PROTOBUFC=OFF"
		"-DWITH_POSTGIS=OFF"
		"-DWITH_WMS=ON"
		"-DWITH_WCS=OFF"
		"-DWITH_WFS=OFF"
		"-DWITH_OGCAPI=OFF"
	)

	echo "${args[@]}"
}

src_configure() {
	if use java; then
		export JAVA_HOME="$(java-config -g JAVA_HOME)"
	fi

	# NOTE: We could make this based on _generate_cmake_args, but
	# then we wouldn't be as-explicit about what is enabled/not,
	# and reliant on defaults not changing.
	# Readability and maintainability is better this way.
	local mycmakeargs=(
		"-DBUILD_TESTING=$(usex test)"
		"-DBUILD_FUZZER_REPRODUCER=OFF"
		"-DCMAKE_SKIP_RPATH=ON"
		"-DINSTALL_LIB_DIR=/usr/$(get_libdir)"
		"-DCMAKE_INSTALL_SYSCONFDIR=/usr/share/${PN}"
		"-DWITH_CLIENT_WMS=ON"
		"-DWITH_CLIENT_WFS=ON"
		"-DWITH_CURL=ON"
		"-DWITH_GIF=ON"
		"-DWITH_ICONV=ON"
		"-DWITH_KML=ON"
		"-DWITH_LIBXML2=ON"
		"-DWITH_PHPNG=OFF"
		"-DWITH_PROTOBUFC=ON"
		"-DWITH_SOS=ON"
		"-DWITH_WMS=ON"
		"-DWITH_WFS=ON"
		"-DWITH_WCS=ON"
		"-DWITH_XMLMAPFILE=ON"
		"-DWITH_APACHE_MODULE=$(usex apache ON OFF)"
		"-DWITH_CAIRO=$(usex cairo ON OFF)"
		"-DWITH_FCGI=$(usex apache ON OFF)"
		"-DWITH_GEOS=$(usex geos ON OFF)"
		"-DWITH_JAVA=$(usex java ON OFF)"
		"-DWITH_ORACLESPATIAL=$(usex oracle ON OFF)"
		"-DWITH_MYSQL=$(usex mysql ON OFF)"
		"-DWITH_FRIBIDI=$(usex bidi ON OFF)"
		"-DWITH_HARFBUZZ=$(usex bidi ON OFF)"
		"-DWITH_POSTGIS=$(usex postgis ON OFF)"
		"-DWITH_PERL=$(usex perl ON OFF)"
	)

	use perl && mycmakeargs+=( "-DCUSTOM_PERL_SITE_ARCH_DIR=$(perl_get_raw_vendorlib)" )

	# Configure the standard build first
	cmake_src_configure

	# Minimal build for bindings
	# Note that we use _generate_cmake_args to get a clean config each time, then add
	# in options as appropriate. Otherwise we'd get contamination between bindings.
	if use python ; then
		mycmakeargs=(
			$(_generate_cmake_args)
			"-DWITH_PYTHON=ON"
		)

		python_foreach_impl cmake_src_configure
		python_foreach_impl python_optimize
	fi
}

src_compile() {
	cmake_src_compile

	if use python ; then
		python_foreach_impl cmake_src_compile
	fi
}

src_test() {
	local -x LD_LIBRARY_PATH="${BUILD_DIR}:${LD_LIBRARY_PATH}"

	cmake_src_test
}

src_install() {
	# Needs to be first
	use apache && webapp_src_preinst

	if use python ; then
		python_foreach_impl cmake_src_install
		python_foreach_impl python_optimize
		remove_egg_info() { rm -rf "${D}/$(python_get_sitedir)"/*.egg-info || die; }
		python_foreach_impl remove_egg_info
	fi

	# Install this last because this build is the most "fully-featured"
	cmake_src_install

	if use apache ; then
		# We need a mapserver symlink available in cgi-bin
		dosym ../../../../../../../usr/bin/mapserv /usr/share/webapps/${PN}/${PV}/hostroot/cgi-bin/mapserv
		webapp_src_install
	fi

	if use java ; then
		java-pkg_dojar "${BUILD_DIR}"/mapscript/java/mapscript.jar
	fi
}

pkg_postinst() {
	use apache && webapp_pkg_postinst
}

pkg_prerm() {
	use apache && webapp_pkg_prerm
}
