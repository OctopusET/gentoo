# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MYP=${PN}$(ver_cut 1-2)
SHVER=$(ver_rs 1 '' $(ver_cut 1-2))

inherit autotools flag-o-matic multilib toolchain-funcs

DESCRIPTION="Extension to Tk, adding new widgets, geometry managers, and misc commands"
HOMEPAGE="https://sourceforge.net/projects/wize/"
SRC_URI="https://downloads.sourceforge.net/wize/${PN}-src-${PV}.zip
	https://dev.gentoo.org/~tupone/distfiles/${P}-debian-patches.tar.gz"

IUSE="jpeg static-libs"
SLOT="0/${SHVER}"
LICENSE="BSD"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x64-solaris"

DEPEND="
	dev-lang/tk:0=
	jpeg? ( media-libs/libjpeg-turbo:0= )
	x11-libs/libX11"
RDEPEND="${DEPEND}"
BDEPEND="app-arch/unzip"

S="${WORKDIR}"/${MYP}

MAKEOPTS+=" -j1"

PATCHES=(
	"${WORKDIR}"/patches/02-debian-all.patch
	"${WORKDIR}"/patches/03-fedora-patch-2.patch
	"${WORKDIR}"/patches/04-fedora-tk8.5.6.patch
	"${WORKDIR}"/patches/05-tk8.5-zoomstack.patch
	"${WORKDIR}"/patches/doc-typos.patch
	"${WORKDIR}"/patches/tcl8.6.patch
	"${WORKDIR}"/patches/tk8.6.patch
	"${WORKDIR}"/patches/install.patch
	"${WORKDIR}"/patches/usetclint.patch
	"${WORKDIR}"/patches/usetkint.patch
	"${WORKDIR}"/patches/table.patch
	"${WORKDIR}"/patches/ldflags.patch
	"${WORKDIR}"/patches/pkgindex.patch
	"${WORKDIR}"/patches/decls.patch
	"${WORKDIR}"/patches/bltnsutil.patch
	"${WORKDIR}"/patches/blthash.patch
	"${WORKDIR}"/patches/const.patch
	"${WORKDIR}"/patches/uninitialized.patch
	"${WORKDIR}"/patches/unused.patch
	"${WORKDIR}"/patches/pointertoint.patch
	"${WORKDIR}"/patches/autoreconf.patch
	"${WORKDIR}"/patches/switch.patch
	"${FILESDIR}"/${P}-gentoo.patch
	"${FILESDIR}"/${P}-darwin.patch
	"${FILESDIR}"/${P}-gbsd.patch
	"${FILESDIR}"/${P}-lto.patch
	"${FILESDIR}"/${P}-parallelMake.patch
)

src_prepare() {
	default
	rm acconfig.h || die
	# Set the correct libdir and drop RPATH
	sed \
		-e "s:\(^libdir=\${exec_prefix}/\)lib:\1$(get_libdir):" \
		-e 's:LD_RUN_PATH=.*$:LD_RUN_PATH="":g' \
		-i configure.in || die "sed configure* failed"
	sed \
		-e "/^scriptdir =/s:lib:$(get_libdir):" \
		-i Makefile.in demos/Makefile.in || die "sed Makefile.in failed"

	sed \
		-e "/AR/s:ar:$(tc-getAR):g" \
		-e 's:0444:0644:g' \
		-i generic/Makefile.in || die

	append-cflags -fPIC

	mv configure.{in,ac} || die
	eautoreconf
}

src_configure() {
	# bug #943722
	append-cflags -std=gnu17

	LC_ALL=C \
	econf \
		--x-includes="${EPREFIX}/usr/include" \
		--x-libraries="${EPREFIX}/usr/$(get_libdir)" \
		--with-blt="${EPREFIX}/usr/$(get_libdir)" \
		--with-tcl="${EPREFIX}/usr/$(get_libdir)" \
		--with-tk="${EPREFIX}/usr/$(get_libdir)" \
		--with-tclincls="${EPREFIX}/usr/include" \
		--with-tkincls="${EPREFIX}/usr/include" \
		--with-tcllibs="${EPREFIX}/usr/$(get_libdir)" \
		--with-tklibs="${EPREFIX}/usr/$(get_libdir)" \
		--with-cflags="${CFLAGS}" \
		--with-gnu-ld \
		$(use_enable jpeg) \
		--with-x \
		CC="$(tc-getCC)"
}

src_compile() {
	emake LDFLAGS="${LDFLAGS}"
}

src_install() {
	sed \
		-e "s:\.\./src/bltwish:${EPREFIX}/usr/bin/bltwish:g" \
		-e "s:\.\./bltwish:${EPREFIX}/usr/bin/bltwish:g" \
		-e "s:/usr/local/bin/bltwish:${EPREFIX}/usr/bin/bltwish:g" \
		-e "s:/usr/local/bin/tclsh:${EPREFIX}/usr/bin/tclsh:g" \
		-i demos/{,scripts/}*.tcl || die

	dodir \
		/usr/bin \
		/usr/$(get_libdir)/${MYP}/demos/bitmaps \
		/usr/share/man/mann \
		/usr/include

	emake INSTALL_ROOT="${D}" install

	dodoc NEWS PROBLEMS README
	docinto html
	dodoc html/*.html
	pushd "${ED}"/usr/share/man/mann
	for f in * ; do
		mv ${f} ${f/.n/.nblt} || die
	done
	popd

	# fix for linking against shared lib with -lBLT or -lBLTlite
	dosym libBLT${SHVER}$(get_libname) /usr/$(get_libdir)/libBLT$(get_libname)
	dosym libBLTlite${SHVER}$(get_libname) /usr/$(get_libdir)/libBLTlite$(get_libname)

	use static-libs || \
		find "${ED}"/usr/$(get_libdir) -name "*.a" -print0 | \
		xargs -r -0 rm -fv
}

pkg_preinst() {
	# Fix 'symlink is blocked by a directory' Bug #907270
	rm -rf "${EROOT}"/usr/$(get_libdir)/${MYP}/demos/bitmaps/hand
	rm -rf "${EROOT}"/usr/$(get_libdir)/${MYP}/demos/bitmaps/hand.backup.*
	rm -rf "${EROOT}"/usr/$(get_libdir)/${MYP}/demos/bitmaps/fish
	rm -rf "${EROOT}"/usr/$(get_libdir)/${MYP}/demos/bitmaps/fish.backup.*
	rm -rf "${EROOT}"/usr/$(get_libdir)/${MYP}/demos/images
	rm -rf "${EROOT}"/usr/$(get_libdir)/${MYP}/demos/images.backup.*
	rm -rf "${EROOT}"/usr/$(get_libdir)/${MYP}/demos/scripts
	rm -rf "${EROOT}"/usr/$(get_libdir)/${MYP}/demos/scripts.backup.*
}
